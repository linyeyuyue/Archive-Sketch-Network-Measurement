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


module bucket_decision_0(
    input wire clk,                     // 时钟
    input wire rst_n,                   // 异步低电平复位
    
    // 输入控制信号
    input wire start,                   // 启动决策信号
    input wire [15:0] current_timest,   // 当前时间戳
    input wire [2:0] bucket_addr        // 桶地址
);

    // 参数定义
    parameter THETA = 16'h0020;         // 阈值θ，Q4.12格式，默认0.125
    parameter MAX_TIME_DIFF = 8'd255;   // 最大时间差限制
    
    // 状态定义
    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] READ = 2'b01;
    parameter [1:0] CALC = 2'b10;
    parameter [1:0] DECIDE = 2'b11;
    
    reg [1:0] state, next_state;
    
    // 寄存器定义
    reg [11:0] addr_reg;                // 桶地址寄存器
    reg [185:0] bucket_data_reg;        // 桶数据寄存器
    reg [15:0] current_timest_reg;      // 当前时间戳寄存器
    
    // 桶字段提取
    wire [31:0] bucket_key = bucket_data_reg[185:154];
    wire [15:0] bucket_timest = bucket_data_reg[25:10];
    wire [9:0] bucket_score = bucket_data_reg[9:0];
    
    // ========== 计算时间差 ==========
    wire [15:0] time_diff = current_timest_reg - bucket_timest;
    
    // 查找表输入
    wire [7:0] delta_t;
    reg ln_lut_valid, inv_lut_valid;
    
    // 查找表输出
    wire [7:0] ln_value;
    wire [15:0] inv_value;
    
    // BRAM接口 - 端口A（写端口）
    reg bram_wea;                // BRAM的写使能
    reg [11:0] bram_addra;       // BRAM写地址
    reg [185:0] bram_dina;       // BRAM写数据
    
    // BRAM接口 - 端口B（读端口）
    reg bram_enb;                // BRAM的读使能
    reg [11:0] bram_addrb;       // BRAM读地址
    wire [185:0] bram_doutb;     // BRAM读数据
    
    // 计算结果
    wire [15:0] v_value;
    
    // 查找表实例化
    ln_lut_8bit ln_lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .score(bucket_score),
        .valid_i(ln_lut_valid),
        .ln_value(ln_value)
    );
    
    inv_lut_16bit inv_lut_inst (
        .clk(clk),
        .rst_n(rst_n),
        .delta_t(delta_t),
        .valid_i(inv_lut_valid),
        .inv_value(inv_value)
    );
    
    // Block RAM实例化
    bucket_row_0 bram_inst (
        .clka(clk),
        .rsta(rst_n),
        .ena(1'b1),
        .wea(bram_wea),
        .addra(bram_addra),
        .dina(bram_dina),
        
        .clkb(clk),
        .rstb(rst_n),
        .enb(bram_enb),
        .web(1'b0),
        .addrb(bram_addrb),
        .doutb(bram_doutb)
    );
    
    // 计算信息价值密度
    wire [23:0] v_full = {8'h00, ln_value} * inv_value;
    assign v_value = v_full[19:4];  // 提取Q4.12格式
    
    // 清空决策逻辑
    wire bucket_empty = (bucket_key == 32'h00000000);
    wire need_clear = (!bucket_empty && (v_value < THETA || (time_diff > MAX_TIME_DIFF)));
    
    // 状态机主逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bram_wea <= 1'b0;
            bram_enb <= 1'b0;
            bram_addra <= 12'h000;
            bram_addrb <= 12'h000;
            bram_dina <= 186'h0;
            ln_lut_valid <= 1'b0;
            inv_lut_valid <= 1'b0;
            current_timest_reg <= 16'h0000;
        end else begin
            state <= next_state;
            
            // 状态退出时的清理操作
            if (state != next_state) begin
                bram_enb <= 1'b0;
                ln_lut_valid <= 1'b0;
                inv_lut_valid <= 1'b0;
            end
            
            case (state)
                IDLE: begin
                    if (start) begin
                        // 锁存输入
                        addr_reg <= bucket_addr;
                        current_timest_reg <= current_timest;
                    end
                end
                
                READ: begin
                    // 发出对应BRAM的读请求
                    bram_enb <= 1'b1;
                    bram_addrb <= addr_reg;
                end
                
                CALC: begin
                    // 锁存读数据
                    bucket_data_reg = bram_doutb;
                    
                    // 启动查找表计算
                    ln_lut_valid <= 1'b1;
                    inv_lut_valid <= 1'b1;
                end
                
                DECIDE: begin
                    if (need_clear) begin
                        bram_wea <= 1'b1;
                        bram_addra <= addr_reg;
                        bram_dina <= 186'h0;
                    end
                end
            endcase
        end
    end
    
    // ========== 下一状态逻辑 ==========
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = READ;
                end
            end
            
            READ: begin
                next_state = CALC;
            end
            
            CALC: begin
                    next_state = DECIDE;
            end
            
            DECIDE: begin
                    next_state = IDLE;
            end
        endcase
    end
    
endmodule