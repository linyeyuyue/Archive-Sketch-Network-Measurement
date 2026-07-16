`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/09 15:43:07
// Design Name: 
// Module Name: top_wrapper
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


module top_wrapper (
    input wire clk,
    input wire rst
);
    
    wire rst_n = ~rst;
    
    wire [31:0] threat_key;
    wire [9:0] threat_score;

    // 内部连线
    wire [31:0] in_flow_key;
    wire [31:0] in_elem;

    // 实例化测试激励生成器
    test_stimulus stim_inst (
        .clk(clk),
        .rst_n(rst_n),
        .test_flow_key(in_flow_key),
        .test_elem(in_elem)
    );

    // 实例化用户顶层模块
    top u_top (
        .clk(clk),
        .rst_n(rst_n),
        .flow_key(in_flow_key),
        .elem(in_elem),
        .threat_key(threat_key),
        .threat_score(threat_score)
    );
endmodule
