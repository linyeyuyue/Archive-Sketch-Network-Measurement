`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/09 15:41:11
// Design Name: 
// Module Name: test_stimulus
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


module test_stimulus (
    input wire clk,
    input wire rst_n,
    output reg [31:0] test_flow_key,
    output reg [31:0] test_elem
);
    
    reg rst_over;
    
    // 测试参数
    localparam NUM_TESTS = 100;      // 发送100组数据
    localparam HOLD_CYCLES = 1;      // 每组数据保持的时钟周期数（原testbench为1）
    localparam GAP_CYCLES  = 9;      // 每组数据之后的间隔周期数
    
    // LFSR种子和多项式 (32位, 多项式 x^32 + x^22 + x^2 + x + 1)
    reg [31:0] lfsr_key;
    reg [31:0] lfsr_elem;
    reg [7:0]  test_cnt;
    reg [3:0]  state;
    reg [3:0]  hold_cnt;
    reg [3:0]  gap_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_flow_key <= 0;
            test_elem <= 0;
            test_cnt <= 0;
            state <= 0;
            hold_cnt <= 0;
            gap_cnt <= 0;
            lfsr_key <= 32'h87654321;   // 随机种子
            lfsr_elem <= 32'h12345678;
            rst_over <= 1;
        end else begin
            case (state)
                0: begin  // 空闲，准备发送新数据
                    if (test_cnt < NUM_TESTS) begin
                        // 输出当前LFSR值
                        test_flow_key <= lfsr_key;
                        test_elem <= lfsr_elem;
                        hold_cnt <= 0;
                        if(rst_over) state <= 1;
                    end
                end

                1: begin  // 保持数据 HOLD_CYCLES 个周期
                    if (hold_cnt < HOLD_CYCLES - 1) begin
                        hold_cnt <= hold_cnt + 1;
                    end else begin
                        test_flow_key <= 0;
                        test_elem <= 0;
                        gap_cnt <= 0;
                        state <= 2;
                    end
                end

                2: begin  // 间隔 GAP_CYCLES 个周期（去除0、1状态机额外占用的2个周期）
                    if (gap_cnt < GAP_CYCLES - 3) begin
                        gap_cnt <= gap_cnt + 1;
                    end else begin
                        // 更新LFSR，产生下一组随机数
                        lfsr_key <= {lfsr_key[30:0], lfsr_key[31] ^ lfsr_key[21] ^ lfsr_key[1] ^ lfsr_key[0]};
                        lfsr_elem <= {lfsr_elem[30:0], lfsr_elem[31] ^ lfsr_elem[21] ^ lfsr_elem[1] ^ lfsr_elem[0]};
                        test_cnt <= test_cnt + 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end
endmodule
