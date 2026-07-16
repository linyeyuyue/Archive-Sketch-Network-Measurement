`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/22 10:58:17
// Design Name: 
// Module Name: hash
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


module addr_hash(
    input wire clk,              // 时钟
    input wire rst_n,            // 异步复位，低有效
    input wire [31:0] key_in,    // 32位输入key
    input wire key_valid,        // 输入有效信号
    
    output reg [11:0] addr_0,    // 第0行地址 (h1)
    output reg [11:0] addr_1,    // 第1行地址 (h2)
    output reg [11:0] addr_2,    // 第2行地址 (h3)
    output reg [11:0] addr_3     // 第3行地址 (h4)
);

    // 参数定义：4个独立的哈希乘数（32位质数）
    // 选择原则：大质数，二进制中1的分布均匀
    localparam MULTIPLIER_0 = 32'hdb9ee205;  // h1乘数 11011011100111101110001000000101 汉明权重17
    localparam MULTIPLIER_1 = 32'h5f47c1c5;  // h2乘数 01011111010001111100000111000101 汉明权重17
    localparam MULTIPLIER_2 = 32'h3b2a7d43;  // h3乘数 00111011001010100111110101000011 汉明权重17
    localparam MULTIPLIER_3 = 32'h19893e35;  // h4乘数 00011001100010010011111000110101 汉明权重15
    
    // 中间信号声明
    wire [63:0] product_0, product_1, product_2, product_3;  // 乘法结果（64位）
    wire [15:0] hash_temp_0, hash_temp_1, hash_temp_2, hash_temp_3;  // 哈希中间值
    
    // 并行哈希计算（组合逻辑部分）
    
    // 哈希函数0 (h1)
    assign product_0 = key_in * MULTIPLIER_0;
    // 取中间位并异或，增加随机性
    assign hash_temp_0 = product_0[31:16] ^ product_0[15:0] ^ key_in[15:0];
    
    // 哈希函数1 (h2)
    assign product_1 = key_in * MULTIPLIER_1;
    assign hash_temp_1 = product_1[31:16] ^ product_1[15:0] ^ key_in[31:16];
    
    // 哈希函数2 (h3)  
    assign product_2 = key_in * MULTIPLIER_2;
    assign hash_temp_2 = product_2[31:16] ^ product_2[15:0] ^ {key_in[15:8], key_in[31:24]};
    
    // 哈希函数3 (h4)
    assign product_3 = key_in * MULTIPLIER_3;
    assign hash_temp_3 = product_3[31:16] ^ product_3[15:0] ^ {key_in[7:0], key_in[23:16]};
    
    // 取模运算：取低12位（因为桶数组宽度=4096=2^12）
    wire [11:0] addr_0_comb, addr_1_comb, addr_2_comb, addr_3_comb;
    assign addr_0_comb = hash_temp_0[11:0];  // 取低12位，相当于 % 4096
    assign addr_1_comb = hash_temp_1[11:0];
    assign addr_2_comb = hash_temp_2[11:0];
    assign addr_3_comb = hash_temp_3[11:0];
    
    // 时序逻辑：寄存器输出，确保时序稳定
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            addr_0 <= 12'd0;
            addr_1 <= 12'd0;
            addr_2 <= 12'd0;
            addr_3 <= 12'd0;
        end else if (key_valid) begin
            // 有效输入时，锁存哈希结果
            addr_0 <= addr_0_comb;
            addr_1 <= addr_1_comb;
            addr_2 <= addr_2_comb;
            addr_3 <= addr_3_comb;
        end
    end
endmodule
