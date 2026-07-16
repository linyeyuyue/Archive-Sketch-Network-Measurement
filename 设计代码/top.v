`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/01/22 10:58:44
// Design Name: 
// Module Name: top
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


module top(
    input wire clk,                     // 系统时钟
    input wire rst_n,                   // 异步低电平复位

    // 输入接口
    input wire [31:0] flow_key,         // 流标识符
    input wire [31:0] elem,             // 流元素特征值（用于哈希）
    
    // 最大威胁流记录寄存器
    output reg [31:0] threat_key,       // 威胁流标识
    output reg [9:0] threat_score       // 威胁流分数
);
    
    localparam [185:0] CLEAR_DATA = 186'h0;
    localparam TIME_CLOCK_CYCLE = 10;
    
    // 时间单位寄存器
    reg [15:0] timest;
    reg [15:0] clk_cnt;

    // 决策模块接口
    reg [31:0] flow_key_deci;
    wire deci_read_req;
    reg [185:0] deci_doutb_0, deci_doutb_1, deci_doutb_2, deci_doutb_3;
    wire need_clear_0, need_clear_1, need_clear_2, need_clear_3;
    wire [11:0] hash_addr_0, hash_addr_1, hash_addr_2, hash_addr_3;
    wire decision_complete;
    reg decision_progress;

    // 更新模块接口
    reg [31:0] flow_key_refr;
    reg [31:0] elem_refr;
    reg [185:0] refr_doutb_0, refr_doutb_1, refr_doutb_2, refr_doutb_3;
    wire refr_wea_0, refr_wea_1, refr_wea_2, refr_wea_3;
    reg [11:0] refr_addr_0, refr_addr_1, refr_addr_2, refr_addr_3;
    wire [185:0] refr_dina_0, refr_dina_1, refr_dina_2, refr_dina_3;
    wire refresh_complete;
    
    // BRAM 接口：复用读写端口，决策模块与更新模块同时读时，更新优先；同时写时，决策优先
    // 桶0 BRAM
    reg bram_wea_0;
    reg [11:0] bram_addra_0;
    reg [185:0] bram_dina_0;
    reg bram_enb_0;
    reg [11:0] bram_addrb_0;
    wire [185:0] bram_doutb_0;

    // 桶1 BRAM
    reg bram_wea_1;
    reg [11:0] bram_addra_1;
    reg [185:0] bram_dina_1;
    reg bram_enb_1;
    reg [11:0] bram_addrb_1;
    wire [185:0] bram_doutb_1;
    
    // 桶2 BRAM
    reg bram_wea_2;
    reg [11:0] bram_addra_2;
    reg [185:0] bram_dina_2;
    reg bram_enb_2;
    reg [11:0] bram_addrb_2;
    wire [185:0] bram_doutb_2;
    
    // 桶3 BRAM
    reg bram_wea_3;
    reg [11:0] bram_addra_3;
    reg [185:0] bram_dina_3;
    reg bram_enb_3;
    reg [11:0] bram_addrb_3;
    wire [185:0] bram_doutb_3;
    
    // 流水线寄存器
    reg [31:0] elem_deci;    
    reg [31:0] flow_key_half;
    reg [31:0] elem_half;
    
    // 控制信号
    reg start_decision;
    reg start_refresh;
    reg wait_refresh;
    reg deci_read_busy;
    reg deci_write_busy;
    reg refr_write_busy;
    
    // 决策模块实例化
    bucket_decision_top decision_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_decision),
        .current_timest(timest),
        .flow_key(flow_key_deci),
        .bucket_data_0(deci_doutb_0),
        .bucket_data_1(deci_doutb_1),
        .bucket_data_2(deci_doutb_2),
        .bucket_data_3(deci_doutb_3),
        .decision_complete(decision_complete),
        .read_req(deci_read_req),
        .hash_addr_0(hash_addr_0),
        .hash_addr_1(hash_addr_1),
        .hash_addr_2(hash_addr_2),
        .hash_addr_3(hash_addr_3),
        .need_clear_0(need_clear_0),
        .need_clear_1(need_clear_1),
        .need_clear_2(need_clear_2),
        .need_clear_3(need_clear_3)
    );
    
    // 更新模块实例化
    bucket_refresh refresh_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_refresh),
        .flow_key(flow_key_refr),
        .current_timest(timest),
        .elem(elem_refr),
        .refresh_wea_0(refr_wea_0),
        .refresh_wea_1(refr_wea_1),
        .refresh_wea_2(refr_wea_2),
        .refresh_wea_3(refr_wea_3),
        .refresh_dina_0(refr_dina_0),
        .refresh_dina_1(refr_dina_1),
        .refresh_dina_2(refr_dina_2),
        .refresh_dina_3(refr_dina_3),
        .refresh_doutb_0(refr_doutb_0),
        .refresh_doutb_1(refr_doutb_1),
        .refresh_doutb_2(refr_doutb_2),
        .refresh_doutb_3(refr_doutb_3),
        .refresh_complete(refresh_complete)
    );

    // 桶寄存器实例化
    bucket_row_0 bram_inst_0 (
        .clka(clk),
        .ena(bram_wea_0),
        .wea(bram_wea_0),
        .addra(bram_addra_0),
        .dina(bram_dina_0),
        .douta(),
        .clkb(clk),
        .enb(bram_enb_0),
        .web(1'b0),
        .addrb(bram_addrb_0),
        .dinb(186'h0),
        .doutb(bram_doutb_0)
    );

    bucket_row_1 bram_inst_1 (
        .clka(clk),
        .ena(bram_wea_1),
        .wea(bram_wea_1),
        .addra(bram_addra_1),
        .dina(bram_dina_1),
        .douta(),
        .clkb(clk),
        .enb(bram_enb_1),
        .web(1'b0),
        .addrb(bram_addrb_1),
        .dinb(186'h0),
        .doutb(bram_doutb_1)
    );

    bucket_row_2 bram_inst_2 (
        .clka(clk),
        .ena(bram_wea_2),
        .wea(bram_wea_2),
        .addra(bram_addra_2),
        .dina(bram_dina_2),
        .douta(),
        .clkb(clk),
        .enb(bram_enb_2),
        .web(1'b0),
        .addrb(bram_addrb_2),
        .dinb(186'h0),
        .doutb(bram_doutb_2)
    );

    bucket_row_3 bram_inst_3 (
        .clka(clk),
        .ena(bram_wea_3),
        .wea(bram_wea_3),
        .addra(bram_addra_3),
        .dina(bram_dina_3),
        .douta(),
        .clkb(clk),
        .enb(bram_enb_3),
        .web(1'b0),
        .addrb(bram_addrb_3),
        .dinb(186'h0),
        .doutb(bram_doutb_3)
    );
    
    // ILA
    ila_0 ILA (
       .clk(clk), // input wire clk
    
       .probe0(threat_key), // input wire [31:0]  probe0  
       .probe1(threat_score), // input wire [9:0]  probe1 
       .probe2(flow_key), // input wire [31:0]  probe2 
       .probe3(elem), // input wire [31:0]  probe3
       
       .probe4(rst_n) // input wire probe4
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_decision <= 0;
            start_refresh <= 0;
            flow_key_deci <= 0;
            flow_key_refr <= 0;
            timest <= 0;
            clk_cnt <= 0;
            deci_doutb_0 <= 0;
            deci_doutb_1 <= 0;
            deci_doutb_2 <= 0;
            deci_doutb_3 <= 0;
            refr_addr_0 <= 0;
            refr_addr_1 <= 0;
            refr_addr_2 <= 0;
            refr_addr_3 <= 0;
            refr_doutb_0 <= 0;
            refr_doutb_1 <= 0;
            refr_doutb_2 <= 0;
            refr_doutb_3 <= 0;
            bram_wea_0 <= 0;
            bram_wea_1 <= 0;
            bram_wea_2 <= 0;
            bram_wea_3 <= 0;
            bram_addra_0 <= 0;
            bram_addra_1 <= 0;
            bram_addra_2 <= 0;
            bram_addra_3 <= 0;
            bram_dina_0 <= 0;
            bram_dina_1 <= 0;
            bram_dina_2 <= 0;
            bram_dina_3 <= 0;
            deci_read_busy <= 0;
            deci_write_busy <= 0;
            wait_refresh <= 0;
            elem_deci <= 0;            
            elem_refr <= 0;
            refr_write_busy <= 0;
            threat_key <= 0;
            threat_score <= 0;
            decision_progress <= 0;
        end else begin
        
            // 系统时间更新
            clk_cnt <= clk_cnt + 1;
            if(clk_cnt == (TIME_CLOCK_CYCLE - 1)) begin
                timest <= timest + 1;
                clk_cnt <= 0;
            end
            
            // 决策启动
            if(flow_key_deci == 32'b0) begin
                flow_key_deci <= flow_key;
                elem_deci <= elem;
            end
            if(flow_key_deci != 32'b0 && !(decision_progress)) begin
                start_decision <= 1'b1;
                decision_progress <= 1'b1;
            end
            if(start_decision) begin
                start_decision <= 1'b0;
            end
            
            // 读操作标识
            if(deci_read_req) begin
                deci_read_busy <= 1'b1;
            end
            
            // 决策数据寄存
            if(deci_read_busy) begin
                deci_doutb_0 <= bram_doutb_0;
                deci_doutb_1 <= bram_doutb_1;
                deci_doutb_2 <= bram_doutb_2;
                deci_doutb_3 <= bram_doutb_3;
                deci_read_busy <= 1'b0;
            end
            
            // 决策完成
            if(decision_complete) begin
                wait_refresh <= 1'b1;
                flow_key_half <= flow_key_deci;
                elem_half <= elem_deci;
                flow_key_deci <= 32'b0;
                elem_deci <= 32'b0;                
                if(!need_clear_0) refr_doutb_0 <= deci_doutb_0;
                if(!need_clear_1) refr_doutb_1 <= deci_doutb_1;
                if(!need_clear_2) refr_doutb_2 <= deci_doutb_2;
                if(!need_clear_3) refr_doutb_3 <= deci_doutb_3;
            end
            
            // 更新启动
            if(wait_refresh && (flow_key_refr == 32'b0)) begin
                flow_key_refr <= flow_key_half;
                elem_refr <= elem_half;
                refr_addr_0 <= hash_addr_0;
                refr_addr_1 <= hash_addr_1;
                refr_addr_2 <= hash_addr_2;
                refr_addr_3 <= hash_addr_3;
                start_refresh <= 1'b1;
                wait_refresh <= 1'b0;
                decision_progress <= 1'b0;
            end
            if(start_refresh) begin
                start_refresh <= 1'b0;
            end
            
            // 更新完成
            if(refresh_complete) begin
                flow_key_refr <= 32'b0;
                refr_addr_0 <= 12'b0;
                refr_addr_1 <= 12'b0;
                refr_addr_2 <= 12'b0;
                refr_addr_3 <= 12'b0;
                elem_refr <= 32'b0;
                refr_doutb_0 <= 186'h0;
                refr_doutb_1 <= 186'h0;
                refr_doutb_2 <= 186'h0;
                refr_doutb_3 <= 186'h0;
            end
            
            // 写操作，决策优先
            if(need_clear_0) begin
                bram_wea_0 <= 1'b1;
                bram_addra_0 <= hash_addr_0;
                bram_dina_0 <= CLEAR_DATA;
                deci_write_busy <= 1'b1;
            end else if(refr_wea_0 && (!deci_write_busy)) begin
                bram_wea_0 <= 1'b1;
                bram_addra_0 <= refr_addr_0;
                bram_dina_0 <= refr_dina_0;
                refr_write_busy <= 1'b1;
            end
            if(need_clear_1) begin
                bram_wea_1 <= 1'b1;
                bram_addra_1 <= hash_addr_1;
                bram_dina_1 <= CLEAR_DATA;
                deci_write_busy <= 1'b1;
            end else if(refr_wea_1 && (!deci_write_busy)) begin
                bram_wea_1 <= 1'b1;
                bram_addra_1 <= refr_addr_1;
                bram_dina_1 <= refr_dina_1;
                refr_write_busy <= 1'b1;
            end
            if(need_clear_2) begin
                bram_wea_2 <= 1'b1;
                bram_addra_2 <= hash_addr_2;
                bram_dina_2 <= CLEAR_DATA;
                deci_write_busy <= 1'b1;
            end else if(refr_wea_2 && (!deci_write_busy)) begin
                bram_wea_2 <= 1'b1;
                bram_addra_2 <= refr_addr_2;
                bram_dina_2 <= refr_dina_2;
                refr_write_busy <= 1'b1;
            end
            if(need_clear_3) begin
                bram_wea_3 <= 1'b1;
                bram_addra_3 <= hash_addr_3;
                bram_dina_3 <= CLEAR_DATA;
                deci_write_busy <= 1'b1;
            end else if(refr_wea_3 && (!deci_write_busy)) begin
                bram_wea_3 <= 1'b1;
                bram_addra_3 <= refr_addr_3;
                bram_dina_3 <= refr_dina_3;
                refr_write_busy <= 1'b1;
            end
            
            // 写入端口清空
            if(deci_write_busy && (!(refr_wea_0 || refr_wea_1 || refr_wea_2 || refr_wea_3))) begin
                bram_addra_0 <= 12'b0;
                bram_addra_1 <= 12'b0;
                bram_addra_2 <= 12'b0;
                bram_addra_3 <= 12'b0;
                deci_write_busy <= 1'b0;
            end
            if(refr_write_busy && (!(need_clear_0 || need_clear_1 || need_clear_2 || need_clear_3))) begin
                bram_addra_0 <= 12'b0;
                bram_addra_1 <= 12'b0;
                bram_addra_2 <= 12'b0;
                bram_addra_3 <= 12'b0;
                refr_write_busy <= 1'b0;
            end
            
            // 写入请求关闭
            if(bram_wea_0) begin
                bram_wea_0 <= 1'b0;
            end
            if(bram_wea_1) begin
                bram_wea_1 <= 1'b0;
            end
            if(bram_wea_2) begin
                bram_wea_2 <= 1'b0;
            end
            if(bram_wea_3) begin
                bram_wea_3 <= 1'b0;
            end
    
            // 记录最大威胁流及位置
            if(refr_wea_0 && refr_dina_0[9:0] >= threat_score) begin
                threat_key <= flow_key_refr;
                threat_score <= refr_dina_0[9:0];
            end
            if(refr_wea_1 && refr_dina_1[9:0] >= threat_score) begin
                threat_key <= flow_key_refr;
                threat_score <= refr_dina_1[9:0];
            end
            if(refr_wea_2 && refr_dina_2[9:0] >= threat_score) begin
                threat_key <= flow_key_refr;
                threat_score <= refr_dina_2[9:0];
            end
            if(refr_wea_3 && refr_dina_3[9:0] >= threat_score) begin
                threat_key <= flow_key_refr;
                threat_score <= refr_dina_3[9:0];
            end
        end
    end
    always @(*) begin
        bram_enb_0 = 1'b0;
        bram_enb_1 = 1'b0;
        bram_enb_2 = 1'b0;
        bram_enb_3 = 1'b0;
        bram_addrb_0 = 12'b0;
        bram_addrb_1 = 12'b0;
        bram_addrb_2 = 12'b0;
        bram_addrb_3 = 12'b0;
        
        if(deci_read_req) begin
            bram_enb_0 = 1'b1;
            bram_enb_1 = 1'b1;
            bram_enb_2 = 1'b1;
            bram_enb_3 = 1'b1;
            bram_addrb_0 = hash_addr_0;
            bram_addrb_1 = hash_addr_1;
            bram_addrb_2 = hash_addr_2;
            bram_addrb_3 = hash_addr_3;
        end
    end
endmodule
