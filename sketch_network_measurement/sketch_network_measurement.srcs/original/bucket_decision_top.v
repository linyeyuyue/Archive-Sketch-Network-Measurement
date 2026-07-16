`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/08 15:24:12
// Design Name: 
// Module Name: bucket_decision_top
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


module bucket_decision_top(
    input wire clk,                     // 时钟
    input wire rst_n,                   // 异步低电平复位
    
    // 输入接口
    input wire start,                   // 启动清空决策
    input wire [15:0] current_timest,   // 当前时间戳
    input wire [31:0] flow_key,         // 流标识符
    input wire [185:0] bucket_data_0, bucket_data_1, bucket_data_2, bucket_data_3,
    
    // 输出接口    
    output reg read_req,                // 读请求
    output wire decision_complete,      // 决策全部完成标识
    output wire [11:0] hash_addr_0, hash_addr_1, hash_addr_2, hash_addr_3,
    output wire need_clear_0, need_clear_1, need_clear_2, need_clear_3
);

    // 信号声明
    // 哈希模块接口
    reg start_hash;
    
    // 清空控制器接口
    reg start_decision;
    wire decision_complete_0, decision_complete_1, decision_complete_2, decision_complete_3;
    
    // 状态定义
    parameter HASH = 2'b00,
              READ = 2'b01,
              DECISION = 2'b10;
    
    reg [1:0] state, next_state;
    
    reg [31:0] flow_key_reg;
    wire key_valid = (flow_key_reg != 32'b0) ? 1'b1: 1'b0;
    assign decision_complete = decision_complete_0 && decision_complete_1 && decision_complete_2 && decision_complete_3;
    
    // 哈希模块实例化
    addr_hash hash_inst (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(flow_key_reg),
        .key_valid(start_hash),
        .addr_0(hash_addr_0),
        .addr_1(hash_addr_1),
        .addr_2(hash_addr_2),
        .addr_3(hash_addr_3)
    );
    
    // 桶清空控制器实例化
    bucket_decision_0 decision_inst_0 (
        .clk(clk),
        .rst_n(rst_n),
        
        // 输入信号
        .start(start_decision),
        .current_timest(current_timest),
        .bucket_data(bucket_data_0),
        
        // 清空请求接收
        .need_clear(need_clear_0),
        
        // 决策完成标识
        .decision_ready(decision_complete_0)
    );
    
    bucket_decision_1 decision_inst_1 (
        .clk(clk),
        .rst_n(rst_n),
        
        // 输入信号
        .start(start_decision),
        .current_timest(current_timest),
        .bucket_data(bucket_data_1),
        
        // 清空请求接收
        .need_clear(need_clear_1),
        
        // 决策完成标识
        .decision_ready(decision_complete_1)
    );
    
    bucket_decision_2 decision_inst_2 (
        .clk(clk),
        .rst_n(rst_n),
        
        // 输入信号
        .start(start_decision),
        .current_timest(current_timest),
        .bucket_data(bucket_data_2),
        
        // 清空请求接收
        .need_clear(need_clear_2),
        
        // 决策完成标识
        .decision_ready(decision_complete_2)
    );
    
    bucket_decision_3 decision_inst_3 (
        .clk(clk),
        .rst_n(rst_n),
        
        // 输入信号
        .start(start_decision),
        .current_timest(current_timest),
        .bucket_data(bucket_data_3),
        
        // 清空请求接收
        .need_clear(need_clear_3),
        
        // 决策完成标识
        .decision_ready(decision_complete_3)
    );
    
    // 控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_hash <= 0;
            start_decision <= 0;
            state <= HASH;
            read_req <= 0;
            flow_key_reg <= 0;
        end else begin
            state <= next_state;
            case (state)
                HASH: begin
                    flow_key_reg <= flow_key;
                    if (start && key_valid) begin
                        start_hash <= 1'b1;
                    end                    
                end
                
                READ: begin
                    read_req <= 1'b1;
                end
                
                DECISION: begin                
                    read_req <= 1'b0;
                    if (start_hash) begin
                        start_hash <= 1'b0;
                        flow_key_reg <= 32'b0;
                        start_decision <= 1'b1;
                    end
                    if (start_decision) begin
                        start_decision <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    // 下一状态逻辑
    always @(*) begin
        next_state = state;
        
        case (state)
            HASH: begin
                if (start && key_valid) begin
                    next_state = READ;
                end
            end
            
            READ: begin
                next_state = DECISION;
            end
            
            DECISION: begin
                if (decision_complete) begin
                    next_state = HASH;
                end
            end
            
            default: next_state = HASH;
        endcase
    end

endmodule
