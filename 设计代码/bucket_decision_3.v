`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/23 09:55:29
// Design Name: 
// Module Name: bucket_decision
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


module bucket_decision_3(
    input wire clk,                     // 时钟
    input wire rst_n,                   // 异步低电平复位
    
    // 输入控制信号
    input wire start,                   // 启动决策信号
    input wire [15:0] current_timest,   // 当前时间戳   
    input wire [185:0] bucket_data,     // 桶数据
    output wire need_clear,             // 发送清空请求
    output reg decision_ready           // 决策完成标识
    
);

    // 参数定义
    parameter THETA = 16'h0006;         // 阈值θ，Q4.12格式，默认0.001465
    
    // 状态定义
    parameter [1:0] IDLE = 2'b00,
                    CALC = 2'b01,
                    DECIDE = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 寄存器定义
    reg [185:0] bucket_data_reg;        // 桶数据寄存器
    reg [15:0] current_timest_reg;      // 当前时间戳寄存器
    
    // 桶字段提取
    wire [31:0] bucket_key = bucket_data_reg[185:154];
    wire [15:0] bucket_timest = bucket_data_reg[25:10];
    wire [7:0] bucket_score = bucket_data_reg[9:2];
    
    // 计算时间差
    wire [15:0] time_diff = current_timest_reg - bucket_timest;
    
    // 查找表输入
    wire [7:0] delta_t = time_diff[7:0];
    reg ln_lut_valid, inv_lut_valid;
    
    // 查找表输出
    wire [7:0] ln_value;
    wire [15:0] inv_value;
    
    // 计算结果
    wire [15:0] v_value;
    
    // 查找表实例化
    ln_lut_8bit_3 ln_lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .score(bucket_score),
        .valid_i(ln_lut_valid),
        .ln_value(ln_value)
    );
    
    inv_lut_16bit_3 inv_lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .delta_t(delta_t),
        .valid_i(inv_lut_valid),
        .inv_value(inv_value)
    );
    
    // 计算信息价值密度
    wire [23:0] v_full = ln_value * inv_value + 24'h000008;// 四舍五入
    assign v_value = v_full[19:4];  // 提取Q4.12格式
    
    // 清空决策逻辑
    wire bucket_empty = (bucket_key == 32'h0);
    assign need_clear = ((!bucket_empty) && (v_value < THETA || (time_diff[15:8] > 0)));
    
    // 状态机主逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ln_lut_valid <= 1'b0;
            inv_lut_valid <= 1'b0;
            current_timest_reg <= 16'h0000;
            decision_ready <= 1'b0;
            bucket_data_reg <= 186'h0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    decision_ready <= 1'b0;
                    // 防止超时情况下need_clear长时持续，同时不影响查找表逻辑
                    if(time_diff[15:8] > 0) begin
                        current_timest_reg <= bucket_timest;
                    end
                    if (start) begin
                        // 锁存时间戳
                        current_timest_reg <= current_timest;
                        // 锁存读数据
                        bucket_data_reg <= bucket_data;
                    end
                end
                
                CALC: begin
                    // 启动查找表计算
                    ln_lut_valid <= 1'b1;
                    inv_lut_valid <= 1'b1;
                end
                
                DECIDE: begin
                    // 关闭查找表
                    ln_lut_valid <= 1'b0;
                    inv_lut_valid <= 1'b0;
                    
                    // 发送决策完成信号
                    decision_ready <= 1'b1;
                end
            endcase
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = CALC;
                end
            end
            
            CALC: begin
                next_state = DECIDE;
            end
            
            DECIDE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
endmodule