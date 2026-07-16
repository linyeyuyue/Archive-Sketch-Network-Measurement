`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/12 14:33:10
// Design Name: 
// Module Name: decision_correction_tb
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


module decision_correction_tb();
    localparam CLK_PERIOD = 20;
    
    parameter [186:0] clear_data = 186'h0;
    parameter NUM_TEST_CASES = 10;
    reg clk;
    
    // 连接到决策顶层的输入信号
    reg start;
    reg rst_n;
    reg [31:0] flow_key;
    reg [15:0] current_timest;
    wire [185:0] bucket_data_0, bucket_data_1, bucket_data_2, bucket_data_3;
    
    // 连接到决策顶层的输出信号
    wire [11:0] hash_addr_0, hash_addr_1, hash_addr_2, hash_addr_3;
    wire need_clear_0, need_clear_1, need_clear_2, need_clear_3;
    reg [185:0] dina_0, dina_1, dina_2, dina_3;
    
    // 测试用信号
    integer i;
    integer error_count, check_count;
    
    // 测试向量寄存器
    reg [31:0] test_keys[0 : NUM_TEST_CASES - 1];
    reg [11:0] test_addr_0[0 : NUM_TEST_CASES - 1];
    reg [11:0] test_addr_1[0 : NUM_TEST_CASES - 1];
    reg [11:0] test_addr_2[0 : NUM_TEST_CASES - 1];
    reg [11:0] test_addr_3[0 : NUM_TEST_CASES - 1];
    reg [153:0] test_data_0[0 : NUM_TEST_CASES - 1];
    reg [153:0] test_data_1[0 : NUM_TEST_CASES - 1];
    reg [153:0] test_data_2[0 : NUM_TEST_CASES - 1];
    reg [153:0] test_data_3[0 : NUM_TEST_CASES - 1];
    reg [3:0] check[0 : NUM_TEST_CASES - 1];
    
    // function监测信号
    wire [7:0] func_lut_addr = need_clear_expected_0.lut_addr;
    wire [15:0] func_time_diff = need_clear_expected_0.time_diff;
    wire [7:0] func_delta_t = need_clear_expected_0.delta_t;
    wire [15:0] func_v_value_expected = need_clear_expected_0.v_value_expected;

    // 时钟生成
    always #(CLK_PERIOD/2) clk = ~clk;
    
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
        .dina(dina_0),
        
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
        .dina(dina_1),
        
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
        .dina(dina_2),
        
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
        .dina(dina_3),
        
        .clkb(clk),
        .enb(r_req),
        .web(1'b0),
        .addrb(hash_addr_3),
        .doutb(bucket_data_3)
    );

    initial begin
        // 生成测试向量
        for (i = 0; i < NUM_TEST_CASES; i = i + 1) begin
            test_keys[i] = $random;
            test_addr_0[i] = calculate_hash_0(test_keys[i]);
            test_addr_1[i] = calculate_hash_1(test_keys[i]);
            test_addr_2[i] = calculate_hash_2(test_keys[i]);
            test_addr_3[i] = calculate_hash_3(test_keys[i]);
            test_data_0[i] = {$random, $random, $random, $random, $random};
            test_data_1[i] = {$random, $random, $random, $random, $random};
            test_data_2[i] = {$random, $random, $random, $random, $random};
            test_data_3[i] = {$random, $random, $random, $random, $random};
        end
    end

    // 测试
    initial begin
        // 初始化所有信号
        clk = 0;
        start = 0;
        rst_n = 0;
        flow_key = 0;
        current_timest = 0;
        error_count = 0;
        check_count = 0;
        dina_0 = clear_data;
        dina_1 = clear_data;
        dina_2 = clear_data;
        dina_3 = clear_data;

        // 复位
        @(posedge clk);
        rst_n = 1;
        #(CLK_PERIOD * 5);
        
        for (i = 0; i < NUM_TEST_CASES; i = i + 1) begin
            force bram_inst_0.ena = 1'b1;
            force bram_inst_1.ena = 1'b1;
            force bram_inst_2.ena = 1'b1;
            force bram_inst_3.ena = 1'b1;
            
            force bram_inst_0.wea = 1'b1;
            force bram_inst_1.wea = 1'b1;
            force bram_inst_2.wea = 1'b1;
            force bram_inst_3.wea = 1'b1;
            
            force hash_addr_0 = test_addr_0[i];
            force hash_addr_1 = test_addr_1[i];
            force hash_addr_2 = test_addr_2[i];
            force hash_addr_3 = test_addr_3[i];
            
            dina_0 = {test_keys[i], test_data_0[i]};
            dina_1 = {test_keys[i], test_data_1[i]};
            dina_2 = {test_keys[i], test_data_2[i]};
            dina_3 = {test_keys[i], test_data_3[i]};
            
            #(CLK_PERIOD);
            
            force bram_inst_0.ena = 1'b0;
            force bram_inst_1.ena = 1'b0;
            force bram_inst_2.ena = 1'b0;
            force bram_inst_3.ena = 1'b0;
            
            force bram_inst_0.wea = 1'b0;
            force bram_inst_1.wea = 1'b0;
            force bram_inst_2.wea = 1'b0;
            force bram_inst_3.wea = 1'b0;
            
            #(CLK_PERIOD * 2);
            
        end
        
        release bram_inst_0.ena;
        release bram_inst_1.ena;
        release bram_inst_2.ena;
        release bram_inst_3.ena;
        
        release bram_inst_0.wea;
        release bram_inst_1.wea;
        release bram_inst_2.wea;
        release bram_inst_3.wea;
        
        release bram_inst_0.addra;
        release bram_inst_1.addra;
        release bram_inst_2.addra;
        release bram_inst_3.addra;
        
        #100;
        
        // 初始化决策模块信号
        start = 0;
        flow_key = 0;
        current_timest = 0;
        error_count = 0;
        check_count = 0;
        
        // 复位
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        
        // 桶1时间差固定为100，测试THETA阈值清空功能，其余桶为随机测试，大部分应聚焦于超过最大时间阈值清空功能
        for (i = 0; i < NUM_TEST_CASES; i = i + 1) begin
            flow_key = test_keys[i];
            current_timest = test_data_0[i][25:10] + 100;
            start = 1;
            #(CLK_PERIOD * 2);
            flow_key = 32'h0;
            start = 0;
            
            // 等待决策完成
            #(CLK_PERIOD * 5);
            
            // 检查结果
            check_count = check_count + 1;
            check[i] = {need_clear_expected_0({test_keys[i], test_data_0[i]}, current_timest),
                        need_clear_expected_1({test_keys[i], test_data_1[i]}, current_timest),
                        need_clear_expected_2({test_keys[i], test_data_2[i]}, current_timest),
                        need_clear_expected_3({test_keys[i], test_data_3[i]}, current_timest)}
                     ^ {uut.decision_inst_0.need_clear,
                        uut.decision_inst_1.need_clear,
                        uut.decision_inst_2.need_clear,
                        uut.decision_inst_3.need_clear};
            if (check[i] !== 4'b0000) begin
                error_count = error_count + 1;
            end
            
            #(CLK_PERIOD * 10);
        end
        
        // 结束仿真
        #(CLK_PERIOD*10);
        
        $finish;
    end
    
    function [11:0] calculate_hash_0;
        input [31:0] key;
        reg [63:0] product;
        reg [31:0] hash_temp;
        begin
            product = key * 32'hdb9e_e205;
            hash_temp = product[31:16] ^ product[15:0] ^ key[15:0];
            calculate_hash_0 = hash_temp[11:0];
        end
    endfunction
    
    function [11:0] calculate_hash_1;
        input [31:0] key;
        reg [63:0] product;
        reg [31:0] hash_temp;
        begin
            product = key * 32'h5f47_c1c5;
            hash_temp = product[31:16] ^ product[15:0] ^ key[31:16];
            calculate_hash_1 = hash_temp[11:0];
        end
    endfunction
    
    function [11:0] calculate_hash_2;
        input [31:0] key;
        reg [63:0] product;
        reg [31:0] hash_temp;
        begin
            product = key * 32'h3b2a_7d43;
            hash_temp = product[31:16] ^ product[15:0] ^ {key[15:8], key[31:24]};
            calculate_hash_2 = hash_temp[11:0];
        end
    endfunction
    
    function [11:0] calculate_hash_3;
        input [31:0] key;
        reg [63:0] product;
        reg [31:0] hash_temp;
        begin
            product = key * 32'h1989_3e35;
            hash_temp = product[31:16] ^ product[15:0] ^ {key[7:0], key[23:16]};
            calculate_hash_3 = hash_temp[11:0];
        end
    endfunction
    
    function need_clear_expected_0;
        input reg [185:0] bucket_data;
        input [15:0] current_timest;
        
        // 提取字段
        reg [31:0] bucket_key;
        reg [15:0] bucket_timest;
        reg [7:0] lut_addr;
        reg [15:0] time_diff;
        reg [7:0] delta_t;
        reg [15:0] v_value_expected;
        begin
            bucket_key = bucket_data[185:154];
            bucket_timest = bucket_data[25:10];
            time_diff = current_timest - bucket_timest;
            if (bucket_key == 32'h0) begin
                need_clear_expected_0 = 0;
            end else if (time_diff[15:8] != 0) begin
                need_clear_expected_0 = 1;
            end else begin
                lut_addr = bucket_data[9:2];
                delta_t = time_diff[7:0];
                // 使用实数计算，四舍五入
                v_value_expected = $rtoi($floor($ln(lut_addr + 1) / delta_t * 4096  + 0.5));
                need_clear_expected_0 = (v_value_expected < 16'h0030) ? 1'b1 : 1'b0;
            end
        end
    endfunction
    
    function need_clear_expected_1;
        input reg [185:0] bucket_data;
        input [15:0] current_timest;
        
        // 提取字段
        reg [31:0] bucket_key;
        reg [15:0] bucket_timest;
        reg [7:0] lut_addr;
        reg [15:0] time_diff;
        reg [7:0] delta_t;
        reg [15:0] v_value_expected;
        begin
            bucket_key = bucket_data[185:154];
            bucket_timest = bucket_data[25:10];
            time_diff = current_timest - bucket_timest;
            if (bucket_key == 32'h0) begin
                need_clear_expected_1 = 0;
            end else if (time_diff[15:8] != 0) begin
                need_clear_expected_1 = 1;
            end else begin
                lut_addr = bucket_data[9:2];
                delta_t = time_diff[7:0];
                // 使用实数计算，四舍五入
                v_value_expected = $rtoi($floor($ln(lut_addr + 1) / delta_t * 4096  + 0.5));
                need_clear_expected_1 = (v_value_expected < 16'h0030) ? 1'b1 : 1'b0;
            end
        end
    endfunction
    
    function need_clear_expected_2;
        input reg [185:0] bucket_data;
        input [15:0] current_timest;
        
        // 提取字段
        reg [31:0] bucket_key;
        reg [15:0] bucket_timest;
        reg [7:0] lut_addr;
        reg [15:0] time_diff;
        reg [7:0] delta_t;
        reg [15:0] v_value_expected;
        begin
            bucket_key = bucket_data[185:154];
            bucket_timest = bucket_data[25:10];
            time_diff = current_timest - bucket_timest;
            if (bucket_key == 32'h0) begin
                need_clear_expected_2 = 0;
            end else if (time_diff[15:8] != 0) begin
                need_clear_expected_2 = 1;
            end else begin
                lut_addr = bucket_data[9:2];
                delta_t = time_diff[7:0];
                // 使用实数计算，四舍五入
                v_value_expected = $rtoi($floor($ln(lut_addr + 1) / delta_t * 4096  + 0.5));
                need_clear_expected_2 = (v_value_expected < 16'h0030) ? 1'b1 : 1'b0;
            end
        end
    endfunction
    
    function need_clear_expected_3;
        input reg [185:0] bucket_data;
        input [15:0] current_timest;
        
        // 提取字段
        reg [31:0] bucket_key;
        reg [15:0] bucket_timest;
        reg [7:0] lut_addr;
        reg [15:0] time_diff;
        reg [7:0] delta_t;
        reg [15:0] v_value_expected;
        begin
            bucket_key = bucket_data[185:154];
            bucket_timest = bucket_data[25:10];
            time_diff = current_timest - bucket_timest;
            if (bucket_key == 32'h0) begin
                need_clear_expected_3 = 0;
            end else if (time_diff[15:8] != 0) begin
                need_clear_expected_3 = 1;
            end else begin
                lut_addr = bucket_data[9:2];
                delta_t = time_diff[7:0];
                // 使用实数计算，四舍五入
                v_value_expected = $rtoi($floor($ln(lut_addr + 1) / delta_t * 4096  + 0.5));
                need_clear_expected_3 = (v_value_expected < 16'h0002) ? 1'b1 : 1'b0;
            end
        end
    endfunction
endmodule
