`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/11 14:44:27
// Design Name: 
// Module Name: bucket_decision_top_tb
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


module bucket_decision_top_tb();
    // 参数定义
    localparam CLK_PERIOD = 20;  // 50MHz时钟
    
    parameter clear_data = 186'h0;
    
    // 输入信号
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] flow_key;
    reg [15:0] current_timest;
    
    // 输出信号
    wire decision_complete;
    
    // 桶数据
    wire [11:0] hash_addr_0, hash_addr_1, hash_addr_2, hash_addr_3;
    wire [185:0] bucket_data_0, bucket_data_1, bucket_data_2, bucket_data_3;
    
    // 实例化顶层模块
    bucket_decision_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .flow_key(flow_key),
        .read_req(r_req),
        .current_timest(current_timest),
        .bucket_data_0(bucket_data_0),
        .bucket_data_1(bucket_data_1),
        .bucket_data_2(bucket_data_2),
        .bucket_data_3(bucket_data_3),
        .hash_addr_0(hash_addr_0),
        .hash_addr_1(hash_addr_1),
        .hash_addr_2(hash_addr_2),
        .hash_addr_3(hash_addr_3),
        .need_clear_0(need_clear_0),
        .need_clear_1(need_clear_1),
        .need_clear_2(need_clear_2),
        .need_clear_3(need_clear_3),
        .decision_complete(decision_complete)
    );
    
    // Block RAM实例化
    bucket_row_0 bram_inst_0 (
        .clka(clk),
        .ena(need_clear_0),
        .wea(need_clear_0),
        .addra(hash_addr_0),
        .dina(clear_data),
        
        .clkb(clk),
        .enb(r_req),
        .web(1'b0),
        .addrb(hash_addr_0),
        .doutb(bucket_data_0)
    );
    
    bucket_row_1 bram_inst_1 (
        .clka(clk),
        .ena(need_clear_1),
        .wea(need_clear_1),
        .addra(hash_addr_1),
        .dina(clear_data),
        
        .clkb(clk),
        .enb(r_req),
        .web(1'b0),
        .addrb(hash_addr_1),
        .doutb(bucket_data_1)
    );
    
    bucket_row_2 bram_inst_2 (
        .clka(clk),
        .ena(need_clear_2),
        .wea(need_clear_2),
        .addra(hash_addr_2),
        .dina(clear_data),
        
        .clkb(clk),
        .enb(r_req),
        .web(1'b0),
        .addrb(hash_addr_2),
        .doutb(bucket_data_2)
    );
    
    bucket_row_3 bram_inst_3 (
        .clka(clk),
        .ena(need_clear_3),
        .wea(need_clear_3),
        .addra(hash_addr_3),
        .dina(clear_data),
        
        .clkb(clk),
        .enb(r_req),
        .web(1'b0),
        .addrb(hash_addr_3),
        .doutb(bucket_data_3)
    );
    
    
    // 时钟生成
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // 测试序列
    integer error_count, check_count;
    integer i;
    
    // 测试
    initial begin
        // 初始化信号
        clk = 0;
        rst_n = 0;
        start = 0;
        flow_key = 0;
        current_timest = 0;
        error_count = 0;
        check_count = 0;
        
        // 复位
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD * 1.5);
        
        // 测试1：基本功能测试
        flow_key = 32'h12345678;
        current_timest = 16'h1000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
        
        // 等待决策完成
        #(CLK_PERIOD * 5);
        
        // 检查结果
        check_count = check_count + 1;
        if (!decision_complete) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD * 10);
        
        // 测试2：连续两次决策
        
        // 第一次决策
        flow_key = 32'hAABBCCDD;
        current_timest = 16'h2000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
          
        #(CLK_PERIOD * 5); // 第一次决策结束
        check_count = check_count + 1;
        if (!decision_complete) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD);
        
        // 第二次决策
        flow_key = 32'hEEFF0011;
        current_timest = 16'h3000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
        
        #(CLK_PERIOD * 5); // 第二次决策结束
        check_count = check_count + 1;
        if (!decision_complete) begin
            error_count = error_count + 1;
        end      
        
        #(CLK_PERIOD * 10);
        
        // 测试3：不同流密钥测试
        
        // 测试多个不同的流密钥
        for (i = 0; i < 5; i = i + 1) begin
            flow_key = $random;
            current_timest = 16'h4000 + i*100;
            start = 1;
            #(CLK_PERIOD * 2);
            flow_key = 32'h0;
            start = 0;
            
            // 等待决策完成
            #(CLK_PERIOD * 5);
            
            check_count = check_count + 1;
            if (!decision_complete) begin
                error_count = error_count + 1;
            end
            
            #(CLK_PERIOD);
        end
        
        #(CLK_PERIOD*10);
        
        // 测试4：复位测试
        
        flow_key = 32'hDEADBEEF;
        current_timest = 16'h5000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
        
        // 在决策过程中复位
        #(CLK_PERIOD*2);
        rst_n = 0;
        #(CLK_PERIOD);
        rst_n = 1;
        #(CLK_PERIOD*2);
        
        check_count = check_count + 1;
        if (decision_complete) begin
            error_count = error_count + 1;
        end
        
        // 重新开始正常决策
        flow_key = 32'hCAFEBABE;
        current_timest = 16'h6000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
        
        // 等待决策完成
        #(CLK_PERIOD * 5);
        
        check_count = check_count + 1;
        if (!decision_complete) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD*10);
        
        // 测试5：边界值测试
        
        // 最小流密钥
        flow_key = 32'h00000001;
        current_timest = 16'h7000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
        
        // 等待决策完成
        #(CLK_PERIOD * 5);
        
        check_count = check_count + 1;
        if (!decision_complete) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD*10);
        
        // 最大流密钥
        flow_key = 32'hFFFFFFFF;
        current_timest = 16'h8000;
        start = 1;
        #(CLK_PERIOD * 2);
        flow_key = 32'h0;
        start = 0;
        
        // 等待决策完成
        #(CLK_PERIOD * 5);
        
        check_count = check_count + 1;
        if (!decision_complete) begin
            error_count = error_count + 1;
        end
        
        // 结束仿真
        #(CLK_PERIOD*10);
        $finish;
    end
endmodule
