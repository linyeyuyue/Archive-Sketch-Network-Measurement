`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/19 16:29:15
// Design Name: 
// Module Name: elem_hash
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


module elem_hash(
    input wire clk,             // 时钟
    input wire rst_n,           // 异步复位，低有效
    input wire [31:0] elem,     // 32位输入数据
    output reg [5:0] elem_hash  // 6位哈希输出
);

    localparam MULTIPLIER = 32'h9E3779B9;

    // 在时钟上升沿更新输出，延迟一个周期
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            elem_hash <= 6'b0;
        else
            // 32位无符号乘法，结果64位，右移26位后取低6位（即原乘积的[31:26]）
            elem_hash <= (elem * MULTIPLIER) >> 26;
    end
endmodule
