`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/09 16:00:02
// Design Name: 
// Module Name: top_wrapper_tb
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


module top_wrapper_tb();

    // 时钟周期参数（与 XDC 中一致，50MHz -> 20ns）
    parameter CLK_PERIOD = 20;   // 20 ns

    reg clk;
    reg rst;

    // 实例化顶层模块（内部包含激励生成器和用户逻辑）
    top_wrapper u_top_wrapper (
        .clk(clk),
        .rst(rst)
    );

    // 产生时钟
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 仿真运行时间
    initial begin
        rst = 1;
        #(CLK_PERIOD * 3)
        rst = 0;
        #32000;
        $finish;
    end
endmodule
