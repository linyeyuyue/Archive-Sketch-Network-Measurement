`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/31 16:36:25
// Design Name: 
// Module Name: top_tb
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


module top_tb();

    // 时钟周期
    parameter CLK_PERIOD = 20;  // 100 MHz 时钟
    
    // 随机测试次数
    parameter NUM_TEST_CASES = 100;
    
    // 测试用信号
    integer i;
    
    // 测试向量寄存器
    reg [31:0] test_keys[0 : NUM_TEST_CASES - 1];
    reg [31:0] test_elem[0 : NUM_TEST_CASES - 1];

    // 输入信号
    reg clk;
    reg rst_n;
    reg [31:0] flow_key;
    reg [31:0] elem;
    
    // 最大威胁流记录寄存器
    wire [31:0] threat_key;
    wire [9:0] threat_score;
    
    // 顶层实例化
    top u_top (
        .clk(clk),
        .rst_n(rst_n),
        .flow_key(flow_key),
        .elem(elem),
        .threat_key(threat_key),
        .threat_score(threat_score)
    );

    // 时钟产生
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        // 生成测试向量
        for (i = 0; i < NUM_TEST_CASES; i = i + 1) begin
            test_keys[i] = $random;
            test_elem[i] = $random;
        end
    end
    
    // 测试
    initial begin
        // 初始化信号
        flow_key = 32'd0;
        elem = 32'd0;
        rst_n = 0;
        i = 0;

        // 复位
        @(posedge clk)
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // 测试1：新流输入（所有桶为空）
        flow_key = 32'h12345678;
        elem = 32'h12345678;
        #(CLK_PERIOD);          // 等待1个时钟周期
        flow_key = 32'd0;       // 清除
        elem = 32'd0;

        #(CLK_PERIOD * 9);

        // 测试2：另一流输入
        flow_key = 32'hAAA12345; // 称该流为流a
        elem = 32'h87654321;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;

        #(CLK_PERIOD * 9);

        // 测试3：连续流输入
        flow_key = 32'hBBB54321; // 称该流为流b
        elem = 32'hDEADBEEF;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        #(CLK_PERIOD * 9);
        flow_key = 32'hCCC23456; // 称该流为流c
        elem = 32'hCAFEBABE;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 穿插随机测试流
        for (i = 0; i < 7; i = i + 1) begin
            flow_key = test_keys[i];
            elem = test_elem[i];
            #(CLK_PERIOD);
            flow_key = 32'd0;
            elem = 32'd0;
            #(CLK_PERIOD * 9);
        end
        
        // 第2次输入流a,元素相同，与上一次输入间隔Δt = 10
        flow_key = 32'hAAA12345;
        elem = 32'h87654321;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 第2次输入流b,元素不同，与上一次输入间隔Δt = 10
        flow_key = 32'hBBB54321;
        elem = 32'hDEADBEEE;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 穿插随机测试流
        for (; i < 15; i = i + 1) begin
            flow_key = test_keys[i];
            elem = test_elem[i];
            #(CLK_PERIOD);
            flow_key = 32'd0;
            elem = 32'd0;
            #(CLK_PERIOD * 9);
        end
        
        // 第3次输入流a,元素相同，与上一次输入间隔Δt = 10
        flow_key = 32'hAAA12345;
        elem = 32'h87654321;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 第3次输入流b,元素不同，与上一次输入间隔Δt = 10
        flow_key = 32'hBBB54321;
        elem = 32'hDEADBEED;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 第2次输入流c,元素相同，与上一次输入间隔Δt = 20
        flow_key = 32'hCCC23456;
        elem = 32'hCAFEBABE;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        
        // 穿插随机测试流
        for (; i < 22; i = i + 1) begin
            flow_key = test_keys[i];
            elem = test_elem[i];
            #(CLK_PERIOD);
            flow_key = 32'd0;
            elem = 32'd0;
            #(CLK_PERIOD * 9);
        end
        
        // 第4次输入流a,元素相同，与上一次输入间隔Δt = 10
        flow_key = 32'hAAA12345;
        elem = 32'h87654321;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 第4次输入流b,元素不同，与上一次输入间隔Δt = 10
        flow_key = 32'hBBB54321;
        elem = 32'hDEADBEEC;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 穿插随机测试流
        for (; i < 30; i = i + 1) begin
            flow_key = test_keys[i];
            elem = test_elem[i];
            #(CLK_PERIOD);
            flow_key = 32'd0;
            elem = 32'd0;
            #(CLK_PERIOD * 9);
        end
        
        // 第5次输入流a,元素相同，与上一次输入间隔Δt = 10
        flow_key = 32'hAAA12345;
        elem = 32'h87654321;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 第5次输入流b,元素不同，与上一次输入间隔Δt = 10
        flow_key = 32'hBBB54321;
        elem = 32'hDEADBEEB;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 第3次输入流c,元素相同，与上一次输入间隔Δt = 20
        flow_key = 32'hCCC23456;
        elem = 32'hCAFEBABE;
        #(CLK_PERIOD);
        flow_key = 32'd0;
        elem = 32'd0;
        
        #(CLK_PERIOD * 9);
        
        // 剩余随机测试流
        for (; i < NUM_TEST_CASES; i = i + 1) begin
            flow_key = test_keys[i];
            elem = test_elem[i];
            #(CLK_PERIOD);
            flow_key = 32'd0;
            elem = 32'd0;
            #(CLK_PERIOD * 9);
        end
        
        // 可以看出，相对而言，流a为持续低基数流，流b为持续高基数流，流c为间断低基数流
        
        // 结束仿真
        #(CLK_PERIOD * 20);
        $finish;
    end
endmodule
