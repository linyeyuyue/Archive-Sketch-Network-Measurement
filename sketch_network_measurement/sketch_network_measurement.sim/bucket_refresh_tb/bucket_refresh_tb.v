`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/20 14:34:23
// Design Name: 
// Module Name: bucket_refresh_tb
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


module bucket_refresh_tb();
    localparam CLK_PERIOD = 20;

    // 时钟与复位
    reg clk;
    reg rst_n;

    // 测试激励
    reg start;
    reg [31:0] flow_key;
    reg [15:0] current_timest;
    reg [31:0] elem;                // 输入到哈希模块的原始元素

    // 顶层模块接口
    wire refresh_wea_0, refresh_wea_1, refresh_wea_2, refresh_wea_3;
    wire [185:0] refresh_dina_0, refresh_dina_1, refresh_dina_2, refresh_dina_3;
    reg read_req;
    wire [185:0] refresh_doutb_0, refresh_doutb_1, refresh_doutb_2, refresh_doutb_3;

    // 桶的地址（固定值，便于验证桶匹配仲裁）
    wire [11:0] refresh_addr_0 = 12'h123;
    wire [11:0] refresh_addr_1 = 12'h456;
    wire [11:0] refresh_addr_2 = 12'h789;
    wire [11:0] refresh_addr_3 = 12'habc;
    
    // 测试标识
    integer check_count, error_count;
    
    // 输入数据监测
    wire [31:0] moni_key = refresh_dina_0[185:154];
    wire [63:0] moni_estim = refresh_dina_0[153:90];
    wire [63:0] moni_mask = refresh_dina_0[89:26];
    wire [15:0] moni_time = refresh_dina_0[25:10];
    wire [9:0] moni_score = refresh_dina_0[9:0];

    // 时钟生成
    always #(CLK_PERIOD / 2) clk = ~clk;

    // 实例化顶层模块
    bucket_refresh dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .flow_key(flow_key),
        .current_timest(current_timest),
        .elem(elem),
        .refresh_wea_0(refresh_wea_0),
        .refresh_wea_1(refresh_wea_1),
        .refresh_wea_2(refresh_wea_2),
        .refresh_wea_3(refresh_wea_3),
        .refresh_dina_0(refresh_dina_0),
        .refresh_dina_1(refresh_dina_1),
        .refresh_dina_2(refresh_dina_2),
        .refresh_dina_3(refresh_dina_3),
        .refresh_doutb_0(refresh_doutb_0),
        .refresh_doutb_1(refresh_doutb_1),
        .refresh_doutb_2(refresh_doutb_2),
        .refresh_doutb_3(refresh_doutb_3)
    );

    // 实例化桶模块
    bucket_row_0 bram_inst_0 (
        .clka(clk),
        .ena(refresh_wea_0),
        .wea(refresh_wea_0),
        .addra(refresh_addr_0),
        .dina(refresh_dina_0),

        .clkb(clk),
        .enb(read_req),
        .web(1'b0),
        .addrb(refresh_addr_0),
        .doutb(refresh_doutb_0)
    );

    bucket_row_1 bram_inst_1 (
        .clka(clk),
        .ena(refresh_wea_1),
        .wea(refresh_wea_1),
        .addra(refresh_addr_1),
        .dina(refresh_dina_1),

        .clkb(clk),
        .enb(read_req),
        .web(1'b0),
        .addrb(refresh_addr_1),
        .doutb(refresh_doutb_1)
    );

    bucket_row_2 bram_inst_2 (
        .clka(clk),
        .ena(refresh_wea_2),
        .wea(refresh_wea_2),
        .addra(refresh_addr_2),
        .dina(refresh_dina_2),

        .clkb(clk),
        .enb(read_req),
        .web(1'b0),
        .addrb(refresh_addr_2),
        .doutb(refresh_doutb_2)
    );

    bucket_row_3 bram_inst_3 (
        .clka(clk),
        .ena(refresh_wea_3),
        .wea(refresh_wea_3),
        .addra(refresh_addr_3),
        .dina(refresh_dina_3),

        .clkb(clk),
        .enb(read_req),
        .web(1'b0),
        .addrb(refresh_addr_3),
        .doutb(refresh_doutb_3)
    );

    // 测试
    initial begin
        // 初始化信号
        clk = 0;
        rst_n = 0;
        start = 0;
        flow_key = 32'h0;
        current_timest = 16'h0;
        elem = 32'h0;
        check_count = 0;
        error_count = 0;
        read_req = 0;

        // 复位
        @(posedge clk)
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);

        // 测试1：新流插入（所有桶为空）
        flow_key = 32'hAABBCCDD;
        current_timest = 16'h10;
        elem = 32'h12345678;    // 提前一个周期设置elem，使得start时hash已稳定
        read_req = 1;           // 提前一个周期读取数据，与顶层设计时序匹配
        #(CLK_PERIOD);
        read_req = 0;
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // 等待处理完成（大约需要7个周期：IDLE->READ->MATCH->CALC1->CALC2->CALC3->WRITE->IDLE）
        #(CLK_PERIOD * 7);
        
        check_count = check_count + 1;
        // 检查写使能：应该只有桶0被写
        if (bram_inst_0.dina[185:154] != 32'hAABBCCDD
         || bram_inst_1.dina[185:154] != 32'h00000000
         || bram_inst_2.dina[185:154] != 32'h00000000
         || bram_inst_3.dina[185:154] != 32'h00000000) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD * 10);

        // 测试2：相同流，不同元素
        flow_key = 32'hAABBCCDD;     // 相同流
        current_timest = 16'h20;     // 时间前进
        elem = 32'h87654321;         // 不同元素，产生不同哈希
        read_req = 1;
        #(CLK_PERIOD);
        read_req = 0;
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        #(CLK_PERIOD * 7);

        // 应该还是写桶0
        check_count = check_count + 1;
        if (bram_inst_0.dina[185:154] != 32'hAABBCCDD
         || bram_inst_1.dina[185:154] != 32'h00000000
         || bram_inst_2.dina[185:154] != 32'h00000000
         || bram_inst_3.dina[185:154] != 32'h00000000) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD * 10);

        // 测试3：新流插入，使用第二个空桶
        flow_key = 32'h11223344;
        current_timest = 16'h30;
        elem = 32'hDEADBEEF;
        read_req = 1;
        #(CLK_PERIOD);
        read_req = 0;
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        #(CLK_PERIOD * 7);
        
        check_count = check_count + 1;
        if (bram_inst_0.dina[185:154] != 32'hAABBCCDD
         || bram_inst_1.dina[185:154] != 32'h11223344
         || bram_inst_2.dina[185:154] != 32'h00000000
         || bram_inst_3.dina[185:154] != 32'h00000000) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD * 10);

        // 测试4：填满所有桶
        // 流3 -> 桶2
        flow_key = 32'h55667788;
        current_timest = 16'h40;
        elem = 32'h11111111;
        read_req = 1;
        #(CLK_PERIOD);
        read_req = 0;
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        #(CLK_PERIOD * 10);

        // 流4 -> 桶3
        flow_key = 32'h99AABBCC;
        current_timest = 16'h50;
        elem = 32'h22222222;
        read_req = 1;
        #(CLK_PERIOD);
        read_req = 0;
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        #(CLK_PERIOD * 7);
        
        check_count = check_count + 1;
        if (bram_inst_0.dina[185:154] != 32'hAABBCCDD
         || bram_inst_1.dina[185:154] != 32'h11223344
         || bram_inst_2.dina[185:154] != 32'h55667788
         || bram_inst_3.dina[185:154] != 32'h99AABBCC) begin
            error_count = error_count + 1;
        end
        
        #(CLK_PERIOD * 10);

        // 测试5：冲突情况（所有桶已满，且无匹配）
        flow_key = 32'hFFFFFFFF;     // 新流，与任何已存流不同
        current_timest = 16'h60;
        elem = 32'h33333333;
        read_req = 1;
        #(CLK_PERIOD);
        read_req = 0;
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        #(CLK_PERIOD * 7);
        
        check_count = check_count + 1;
        if (bram_inst_0.dina[185:154] != 32'hAABBCCDD
         || bram_inst_1.dina[185:154] != 32'h11223344
         || bram_inst_2.dina[185:154] != 32'h55667788
         || bram_inst_3.dina[185:154] != 32'h99AABBCC) begin
            error_count = error_count + 1;
        end
        
        #100;
        $finish;
    end
endmodule
