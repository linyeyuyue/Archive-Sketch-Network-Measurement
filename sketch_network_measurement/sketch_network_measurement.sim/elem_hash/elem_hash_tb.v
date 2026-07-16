`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/07 15:48:42
// Design Name: 
// Module Name: elem_hash_tb
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


`timescale 1ns / 1ps

module elem_hash_tb();

    parameter CLK_PERIOD = 20;  // 50 MHz 时钟

    // 信号声明
    reg         clk;
    reg         rst_n;
    reg  [31:0] elem;
    wire [5:0]  elem_hash;

    // 实例化被测模块
    elem_hash u_elem_hash (
        .clk       (clk),
        .rst_n     (rst_n),
        .elem      (elem),
        .elem_hash (elem_hash)
    );

    // 时钟生成：周期 10ns
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 测试过程
    integer i;
    initial begin
        // 初始化
        clk = 0;
        rst_n = 0;
        elem = 0;

        // 复位释放
        #(CLK_PERIOD);                // 等待一个半时钟周期，确保复位稳定
        rst_n = 1;
        @(posedge clk)                // 时钟边沿对齐

        // 随机输入 100 个值
        for (i = 0; i < 100; i = i + 1) begin
            #(CLK_PERIOD); // 等待时钟上升沿，此时模块会采样 elem
            elem = $random;       // 赋值后，模块将在下一个时钟上升沿输出结果
        end

        // 仿真结束
        $finish;
    end
endmodule
