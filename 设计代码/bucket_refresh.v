`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/22 10:58:44
// Design Name: 
// Module Name: bucket_refresh
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module bucket_refresh(
    input wire clk,                     // 时钟
    input wire rst_n,                   // 异步低电平复位
    input wire start,                   // 启动信号
    input wire [31:0] flow_key,         // 流标识符
    input wire [15:0] current_timest,   // 当前时间戳
    input wire [31:0] elem,
    input wire [185:0] refresh_doutb_0, refresh_doutb_1, refresh_doutb_2, refresh_doutb_3,
    output reg refresh_wea_0, refresh_wea_1, refresh_wea_2, refresh_wea_3,
    output reg [185:0] refresh_dina_0, refresh_dina_1, refresh_dina_2, refresh_dina_3,
    output reg refresh_complete
    );
    
    // 参数定义
    // 权重系数
    parameter omega_1 = 512;   // 基数特征权重(0.5)
    parameter omega_2 = 512;   // 时间模式权重(0.5)
    parameter alpha_1 = 512;   // 指数平滑因子
    parameter alpha_2 = 512;   // 指数平滑因子

    // 状态机
    localparam IDLE   = 3'b000,
               MATCH  = 3'b001,
               CALC_1 = 3'b010,
               CALC_2 = 3'b011,
               CALC_3 = 3'b100,
               WRITE  = 3'b101;

    reg [2:0] state, next_state;

    // 输入寄存器
    reg [31:0] flow_key_reg;
    reg [15:0] timest_reg;
    
    // 元素哈希寄存器
    wire [5:0] elem_hash;
    
    // 查找表接口信号
    reg estim_lut_valid;
    reg dis_lut_valid;
    
    // 桶数据寄存器
    reg [185:0] bucket_data_reg_0, bucket_data_reg_1, bucket_data_reg_2, bucket_data_reg_3;
    reg [63:0] bucket_estim_0, bucket_estim_1, bucket_estim_2, bucket_estim_3;
    reg [63:0] bucket_mask_0, bucket_mask_1, bucket_mask_2, bucket_mask_3;
    reg [15:0] bucket_time_0, bucket_time_1, bucket_time_2, bucket_time_3;
    reg [9:0] bucket_score_0, bucket_score_1, bucket_score_2, bucket_score_3;
    
    // 中间寄存器
    
    reg [63:0] bucket_mask_0_next, bucket_mask_1_next, bucket_mask_2_next, bucket_mask_3_next;
    reg [63:0] bucket_estim_0_next, bucket_estim_1_next, bucket_estim_2_next, bucket_estim_3_next;
    
    // 桶新数据寄存器
    reg [185:0] bucket_data_new_reg;
    reg [63:0] bucket_estim_new_reg;
    reg [63:0] bucket_mask_new_reg;
    reg [9:0] bucket_score_new_reg;
    
    // 桶状态判断信号
    wire [3:0] bucket_match = {(bucket_data_reg_0[185:154] == flow_key_reg),
                               (bucket_data_reg_1[185:154] == flow_key_reg),
                               (bucket_data_reg_2[185:154] == flow_key_reg),
                               (bucket_data_reg_3[185:154] == flow_key_reg)};
    wire [3:0] bucket_usable = {(bucket_data_reg_3[185:154] == 32'b0),
                                (bucket_data_reg_2[185:154] == 32'b0),
                                (bucket_data_reg_1[185:154] == 32'b0),
                                (bucket_data_reg_0[185:154] == 32'b0)};
    wire [15:0] time_diff_0 = timest_reg - bucket_time_0;
    wire [15:0] time_diff_1 = timest_reg - bucket_time_1;
    wire [15:0] time_diff_2 = timest_reg - bucket_time_2;
    wire [15:0] time_diff_3 = timest_reg - bucket_time_3;
    reg [1:0] bucket_use;
    reg bucket_conflict;
    
    // 评分计算中间信号
    reg [5:0] zero_estim;
    reg [5:0] pop_mask;
    reg [5:0] dis;
    wire [15:0] inv_n_value;
    wire [15:0] dis_inv_value;
    reg [27:0] score_temp; // Q1.27定点小数
    reg [37:0] score_full;
    
    // 元素特征哈希实例化
    elem_hash hash_inst (
        .clk(clk),
        .rst_n(rst_n),
        .elem(elem),
        .elem_hash(elem_hash)
    );
    
    // 查找表实例化
    estim_calc_lut lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .zero_estim(zero_estim),
        .valid_i(estim_lut_valid),
        .inv_n_value(inv_n_value)
    );
    
    dis_inv_lut inv_lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .dis(dis),
        .valid_i(dis_lut_valid),
        .inv_value(dis_inv_value)
    );

    // 状态机时序
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            flow_key_reg <= 0;
            timest_reg <= 0;
            refresh_wea_0 <= 0;
            refresh_wea_1 <= 0;
            refresh_wea_2 <= 0;
            refresh_wea_3 <= 0;
            refresh_dina_0 <= 0;
            refresh_dina_1 <= 0;
            refresh_dina_2 <= 0;
            refresh_dina_3 <= 0;
            bucket_conflict <= 0;
            estim_lut_valid <= 0;
            dis_lut_valid <= 0;
            bucket_estim_0 <= 0;
            bucket_estim_1 <= 0;
            bucket_estim_2 <= 0;
            bucket_estim_3 <= 0;
            bucket_mask_0 <= 0;
            bucket_mask_1 <= 0;
            bucket_mask_2 <= 0;
            bucket_mask_3 <= 0;
            bucket_time_0 <= 0;
            bucket_time_1 <= 0;
            bucket_time_2 <= 0;
            bucket_time_3 <= 0;
            bucket_score_0 <= 0;
            bucket_score_1 <= 0;
            bucket_score_2 <= 0;
            bucket_score_3 <= 0;
            bucket_data_new_reg <= 0;
            bucket_estim_new_reg <= 0;
            bucket_mask_new_reg <= 0;
            dis <= 0;
            pop_mask <= 0;
            refresh_complete <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    refresh_wea_0 <= 1'b0;
                    refresh_wea_1 <= 1'b0;
                    refresh_wea_2 <= 1'b0;
                    refresh_wea_3 <= 1'b0;
                    bucket_conflict <= 1'b0;
                    if (start) begin
                        flow_key_reg <= flow_key;
                        timest_reg <= current_timest;
                    end
                end
                MATCH: begin
                    // 存储基数估计向量
                    bucket_estim_0 <= bucket_data_reg_0[153:90];
                    bucket_estim_1 <= bucket_data_reg_1[153:90];
                    bucket_estim_2 <= bucket_data_reg_2[153:90];
                    bucket_estim_3 <= bucket_data_reg_3[153:90];
                    // 存储时间活性位图
                    bucket_mask_0 <= bucket_data_reg_0[89:26];
                    bucket_mask_1 <= bucket_data_reg_1[89:26];
                    bucket_mask_2 <= bucket_data_reg_2[89:26];
                    bucket_mask_3 <= bucket_data_reg_3[89:26];
                    // 存储上次更新时间
                    bucket_time_0 <= bucket_data_reg_0[25:10];
                    bucket_time_1 <= bucket_data_reg_1[25:10];
                    bucket_time_2 <= bucket_data_reg_2[25:10];
                    bucket_time_3 <= bucket_data_reg_3[25:10];
                    // 存储动态威胁评分
                    bucket_score_0 <= bucket_data_reg_0[9:0];
                    bucket_score_1 <= bucket_data_reg_1[9:0];
                    bucket_score_2 <= bucket_data_reg_2[9:0];
                    bucket_score_3 <= bucket_data_reg_3[9:0];                    
                    // 桶匹配
                    if (bucket_match != 4'b0) begin
                        case (bucket_match)
                            4'b1000:
                                bucket_use <= 2'b00;
                            4'b0100:
                                bucket_use <= 2'b01;
                            4'b0010:
                                bucket_use <= 2'b10;
                            4'b0001:
                                bucket_use <= 2'b11;
                        endcase
                    end else begin
                        if (bucket_usable[0]) begin
                            bucket_use <= 2'b00;
                        end else if (bucket_usable[1]) begin
                            bucket_use <= 2'b01;
                        end else if (bucket_usable[2]) begin
                            bucket_use <= 2'b10;
                        end else if (bucket_usable[3]) begin
                            bucket_use <= 2'b11;
                        end else begin
                            bucket_conflict <= 1'b1;
                        end
                    end
                end
                CALC_1: begin
                    estim_lut_valid <= 1'b1;
                    dis_lut_valid <= 1'b1;
                    if (!bucket_conflict) begin
                        case (bucket_use)
                            2'b00: begin
                                bucket_estim_new_reg <= bucket_estim_0_next;
                                bucket_mask_new_reg <= bucket_mask_0_next;
                                if (time_diff_0 > 64) begin
                                    dis <= 1;
                                    pop_mask <= 1;
                                end else begin
                                    dis <= highest_one(bucket_mask_0_next) + 1;
                                    pop_mask <= popcount(bucket_mask_0_next);
                                end
                            end
                            2'b01: begin
                                bucket_estim_new_reg <= bucket_estim_1_next;
                                bucket_mask_new_reg <= bucket_mask_1_next;
                                if (time_diff_1 > 64) begin
                                    dis <= 1;
                                    pop_mask <= 1;
                                end else begin
                                    dis <= highest_one(bucket_mask_1_next) + 1;
                                    pop_mask <= popcount(bucket_mask_1_next);
                                end
                            end
                            2'b10: begin
                                bucket_estim_new_reg <= bucket_estim_2_next;
                                bucket_mask_new_reg <= bucket_mask_2_next;
                                if (time_diff_2 > 64) begin
                                    dis <= 1;
                                    pop_mask <= 1;
                                end else begin
                                    dis <= highest_one(bucket_mask_2_next) + 1;
                                    pop_mask <= popcount(bucket_mask_2_next);
                                end
                            end
                            2'b11: begin
                                bucket_estim_new_reg <= bucket_estim_3_next;
                                bucket_mask_new_reg <= bucket_mask_3_next;
                                if (time_diff_3 > 64) begin
                                    dis <= 1;
                                    pop_mask <= 1;
                                end else begin
                                    dis <= highest_one(bucket_mask_3_next) + 1;
                                    pop_mask <= popcount(bucket_mask_3_next);
                                end
                            end
                        endcase
                    end
                end
                CALC_2: begin
                    estim_lut_valid <= 1'b0;
                    dis_lut_valid <= 1'b0;
                end
                CALC_3: begin
                    // 组装新桶
                    bucket_data_new_reg <= {flow_key_reg,
                                           bucket_estim_new_reg,
                                           bucket_mask_new_reg,
                                           timest_reg,
                                           bucket_score_new_reg};
                    dis <= 0;
                    pop_mask <= 0;
                end
                WRITE: begin
                    if(!bucket_conflict) begin
                        case (bucket_use)
                            2'b00: begin
                                refresh_wea_0 <= 1'b1;
                                refresh_dina_0 <= bucket_data_new_reg;
                            end
                            2'b01: begin
                                refresh_wea_1 <= 1'b1;
                                refresh_dina_1 <= bucket_data_new_reg;
                            end
                            2'b10: begin
                                refresh_wea_2 <= 1'b1;
                                refresh_dina_2 <= bucket_data_new_reg;
                            end
                            2'b11: begin
                                refresh_wea_3 <= 1'b1;
                                refresh_dina_3 <= bucket_data_new_reg;
                            end
                        endcase
                    end
                    refresh_complete <= 1'b1;
                end
            endcase
            if(refresh_complete) begin
                refresh_complete <= 1'b0;
            end
        end
    end

    // 组合逻辑部分
    always @(*) begin
        zero_estim = 64 - popcount(bucket_estim_new_reg);
        bucket_data_reg_0 = refresh_doutb_0;
        bucket_data_reg_1 = refresh_doutb_1;
        bucket_data_reg_2 = refresh_doutb_2;
        bucket_data_reg_3 = refresh_doutb_3;
        bucket_estim_0_next = 64'h0;
        bucket_estim_1_next = 64'h0;
        bucket_estim_2_next = 64'h0;
        bucket_estim_3_next = 64'h0;
        bucket_mask_0_next = 64'h0;
        bucket_mask_1_next = 64'h0;
        bucket_mask_2_next = 64'h0;
        bucket_mask_3_next = 64'h0;
        bucket_score_new_reg = 10'h0;
        case (state)
            IDLE: begin
                bucket_data_reg_0 = 186'h0;
                bucket_data_reg_1 = 186'h0;
                bucket_data_reg_2 = 186'h0;
                bucket_data_reg_3 = 186'h0;
            end
            CALC_1: begin
                if (!bucket_conflict) begin
                    case (bucket_use)
                        2'b00: begin
                            if (time_diff_0 > 64) begin
                                bucket_mask_0_next = 64'h1;
                            end else begin
                                bucket_mask_0_next = bucket_mask_0 << time_diff_0 | 1'b1;
                            end
                            bucket_estim_0_next = bucket_estim_0;
                            bucket_estim_0_next[elem_hash] = 1'b1;
                        end
                        2'b01: begin
                            if (time_diff_1 > 64) begin
                                bucket_mask_1_next = 64'h1;
                            end else begin
                                bucket_mask_1_next = bucket_mask_1 << time_diff_1 | 1'b1;
                            end
                            bucket_estim_1_next = bucket_estim_1;
                            bucket_estim_1_next[elem_hash] = 1'b1;
                        end
                        2'b10: begin
                            if (time_diff_2 > 64) begin
                                bucket_mask_2_next = 64'h1;
                            end else begin
                                bucket_mask_2_next = bucket_mask_2 << time_diff_2 | 1'b1;
                            end
                            bucket_estim_2_next = bucket_estim_2;
                            bucket_estim_2_next[elem_hash] = 1'b1;
                        end
                        2'b11: begin
                            if (time_diff_3 > 64) begin
                                bucket_mask_3_next = 64'h1;
                            end else begin
                                bucket_mask_3_next = bucket_mask_3 << time_diff_3 | 1'b1;
                            end
                            bucket_estim_3_next = bucket_estim_3;
                            bucket_estim_3_next[elem_hash] = 1'b1;
                        end
                    endcase
                end
            end
            CALC_3: begin
                // inv_n_value、pop_mask * dis_inv_value最大值实际上是Q1.12格式
                // 则由于omega为Q0.9格式的权重系数
                // omega_1 * inv_n_value + omega_2 * pop_mask * dis_inv_value应为Q1.21格式
                // 又由于此处dis实际上是dis/len，为Q0.6格式
                // 则score_temp为Q1.27格式
                score_temp = (omega_1 * inv_n_value + omega_2 * pop_mask * dis_inv_value) * dis;
                case (bucket_use)
                    2'b00: begin
                        // 所以bucket_score作为Q1.9格式，应乘19'h40000对齐小数点
                        // score_full为Q1.37格式
                        score_full = score_temp * alpha_1 + bucket_score_0 * alpha_2 * 19'h40000;
                        bucket_score_new_reg = score_full[37:28];
                    end
                    2'b01: begin
                        score_full = score_temp * alpha_1 + bucket_score_1 * alpha_2 * 19'h40000;
                        bucket_score_new_reg = score_full[37:28];
                    end
                    2'b10: begin
                        score_full = score_temp * alpha_1 + bucket_score_2 * alpha_2 * 19'h40000;
                        bucket_score_new_reg = score_full[37:28];
                    end
                    2'b11: begin
                        score_full = score_temp * alpha_1 + bucket_score_3 * alpha_2 * 19'h40000;
                        bucket_score_new_reg = score_full[37:28];
                    end
                endcase
            end
            WRITE: begin
                bucket_data_reg_0 = 186'h0;
                bucket_data_reg_1 = 186'h0;
                bucket_data_reg_2 = 186'h0;
                bucket_data_reg_3 = 186'h0;
            end
            default: ;
        endcase
    end

    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:
                if (start) begin
                    next_state = MATCH;
                end
            MATCH:
                next_state = CALC_1;
            CALC_1:
                if (!bucket_conflict) begin
                    next_state = CALC_2;
                end else begin
                    next_state = WRITE;
                end
            CALC_2:
                next_state = CALC_3;
            CALC_3:
                next_state = WRITE;
            WRITE:
                next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 辅助函数
    function [5:0] popcount;
        input [63:0] data;
        integer i;
        begin
            popcount = 0;
            for (i=0; i<64; i=i+1) begin
                if (data[i]) popcount = popcount + 1;
            end
        end
    endfunction

    function [5:0] highest_one;
        input [63:0] data;
        integer j;
        reg found;
        begin
            highest_one = 0;
            found = 1'b0;
            for (j = 63; j >= 0; j = j - 1) begin
                if (!found && data[j]) begin
                    highest_one = j;
                    found = 1'b1;
                end
            end
        end
    endfunction
endmodule
