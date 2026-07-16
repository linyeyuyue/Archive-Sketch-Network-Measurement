`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/03 15:40:25
// Design Name: 
// Module Name: bucket_row_tb
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


module bucket_row_tb();
    localparam CLK_PERIOD = 20;

    // 连接到被测模块 (UUT) 的输入输出信号
    reg clk;
    reg ena, enb;
    reg wea, web;
    reg [11:0] addra, addrb;
    reg [185:0] dina, dinb;
    wire [185:0] douta, doutb;

    integer error_count, test_count;

    // 时钟生成
    always #(CLK_PERIOD/2) clk = ~clk;

    // 实例化 bucket_row_0 模块
    bucket_row_0 uut (
        .clka(clk),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .clkb(clk),
        .enb(enb),
        .web(web),
        .addrb(addrb),
        .dinb(dinb),
        .doutb(doutb)
    );
    
    // 主测试过程
    initial begin
        // 初始化所有输入信号
        clk = 0;
        ena = 0;
        enb = 0;
        wea = 0;
        web = 0;
        addra = 0; addrb = 0;
        dina = 0; dinb = 0;
        
        error_count = 0;
        test_count = 0;

        // 等待全局稳定
        #100;
        @(posedge clk);
        
        // 测试1: 端口A基本读写
        // 写入操作 (地址 0x010， 数据 186'hA...A)
        ena = 1; // 使能端口A
        wea = 1;
        addra = 12'h010;
        dina = 186'h0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        #(CLK_PERIOD * 4);
        // 切换到读操作
        wea = 0;
        #CLK_PERIOD; // 等待一个周期，读取新数据
        if (douta !== dina) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        ena = 0;
        #(CLK_PERIOD * 10);

        // 测试2: 端口B基本读写
        // 写入操作 (地址 0x020， 数据 186'h5...5)
        enb = 1;
        web = 1;
        addrb = 12'h020;
        dinb = 186'h05555555555555555555555555555555555555555555555;
        #CLK_PERIOD;
        web = 0;
        #CLK_PERIOD;
        if (doutb !== dinb) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        enb = 0;
        #(CLK_PERIOD * 10);

        // 测试3: 控制信号测试 (ena=0)
        ena = 0; // 关闭端口A使能
        wea = 1;
        addra = 12'h010; // 地址是之前写入的有效地址
        dina = 186'h0BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB;
        #(CLK_PERIOD * 4);
        // 当 ena=0 时，输出应为未知态(x)或保持上次值
        if (douta === dina) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        ena = 1; // 恢复使能
        #CLK_PERIOD;
        wea = 0;
        ena = 0; enb = 0;
        #(CLK_PERIOD * 10);

        // 测试4: 边界地址测试
        // 写最大地址
        ena = 1; enb = 1;
        wea = 1;
        addra = 12'hFFF; // 4095
        dina = 186'h3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #(CLK_PERIOD * 4);
        wea = 0;
        #CLK_PERIOD;
        if (douta !== dina) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        ena = 0; enb = 0;
        #(CLK_PERIOD * 10);

        // 写地址0
        ena = 1; enb = 1;
        addra = 0;
        dina = 186'h11111111111111111111111111111111111111111111111;
        wea = 1;
        #(CLK_PERIOD * 4);
        wea = 0;
        #CLK_PERIOD;
        if (douta !== dina) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        ena = 0; enb = 0;
        #(CLK_PERIOD * 10);
        
        // 测试5: 双端口同时操作（不同地址）
        // A读0x010，B写0x030
        ena = 1; enb = 1;
        wea = 0; web = 1;
        addra = 12'h010;
        addrb = 12'h030;
        dinb = 186'h0ADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
        #(CLK_PERIOD * 2);
        web = 0;
        #CLK_PERIOD; // A端口的写入完成，B端口的读取完成
        // 检查B端口读出的旧数据
        if (douta !== 186'h0BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        // 再读A端口新写入的数据
        addrb = 12'h030;
        #CLK_PERIOD;
        if (doutb !== dinb) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        ena = 0; enb = 0;
        #(CLK_PERIOD * 10);
        
        // 测试6: 双端口同时操作（相同地址）
        // A写B读，均为0x020
        ena = 1;
        wea = 1;
        enb = 1;
        web = 0;
        addra = 12'h020;
        dina = 186'h05555555555555555555555555555555555555555555555;
        addrb = 12'h020;
        #CLK_PERIOD;
        wea = 0;
        #CLK_PERIOD;
        // 检查B端口读出的旧数据
        if (doutb !== 186'h05555555555555555555555555555555555555555555555) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        // 再读A端口新写入的数据
        #CLK_PERIOD;
        if (doutb !== dina) begin
            error_count = error_count + 1;
        end
        test_count = test_count + 1;
        ena = 0; enb = 0;

        #100
        
        $finish; // 结束仿真
    end
endmodule
