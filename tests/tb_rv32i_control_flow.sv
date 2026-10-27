`timescale 1ns/1ps

module tb_rv32i_control_flow;

    logic clk = 0;
    logic rst_n = 0;
    logic [31:0] pc, instr;
    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    logic [3:0] mem_wstrb;
    logic mem_we;

    logic [31:0] imem [0:15];
    logic [31:0] data_mem [0:63];

    integer errors = 0;
    integer cycles = 0;

    always #5 clk = ~clk;

    rv32i_core dut (
        .clk(clk), .rst_n(rst_n),
        .pc(pc), .instr(instr),
        .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb), .mem_we(mem_we),
        .mem_rdata(mem_rdata)
    );

    always @(*) begin
        if ((pc[31:2] < 16) && (pc[1:0] == 2'b00))
            instr = imem[pc[5:2]];
        else
            instr = 32'h00000013;

        mem_rdata = data_mem[mem_addr[7:2]];
    end

    always @(posedge clk) begin
        if (rst_n && mem_we)
            data_mem[mem_addr[7:2]] <= mem_wdata;
    end

    function automatic [31:0] enc_i(
        input integer imm_i,
        input integer rs1_i,
        input integer funct3_i,
        input integer rd_i,
        input integer opcode_i
    );
        enc_i = {
            imm_i[11:0], rs1_i[4:0], funct3_i[2:0],
            rd_i[4:0], opcode_i[6:0]
        };
    endfunction

    function automatic [31:0] enc_b(
        input integer imm_b,
        input integer rs2_i,
        input integer rs1_i,
        input integer funct3_i
    );
        enc_b = {
            imm_b[12], imm_b[10:5],
            rs2_i[4:0], rs1_i[4:0],
            funct3_i[2:0], imm_b[4:1],
            imm_b[11], 7'b1100011
        };
    endfunction

    function automatic [31:0] enc_j(
        input integer imm_j,
        input integer rd_i
    );
        enc_j = {
            imm_j[20], imm_j[10:1], imm_j[11],
            imm_j[19:12], rd_i[4:0], 7'b1101111
        };
    endfunction

    task automatic check_reg(
        input integer reg_num,
        input logic [31:0] expected
    );
        begin
            if (dut.regs[reg_num] !== expected) begin
                $display("FAIL x%0d expected %h got %h",
                         reg_num, expected, dut.regs[reg_num]);
                errors = errors + 1;
            end else begin
                $display("PASS x%0d = %h", reg_num, expected);
            end
        end
    endtask

    initial begin
        for (integer i = 0; i < 16; i = i + 1)
            imem[i] = 32'h00000013;

        for (integer j = 0; j < 64; j = j + 1)
            data_mem[j] = 32'd0;

        // 0: x1 = 5
        // 1: x2 = 5
        // 2: BEQ x1,x2,+8 -> instruction 4
        // 3: skipped; x3 must not become 99
        // 4: BNE x1,x2,+8 -> not taken
        // 5: x3 = 7
        // 6: JAL x4,+8 -> instruction 8; x4 = PC+4
        // 7: skipped
        // 8: x5 = 1
        // 9: x7 = 44
        // 10: JALR x6,4(x7) -> PC=48; x6 = PC+4
        // 11: skipped
        // 12: x8 = 8

        imem[0]  = enc_i(5, 0, 3'b000, 1, 7'b0010011);
        imem[1]  = enc_i(5, 0, 3'b000, 2, 7'b0010011);
        imem[2]  = enc_b(8, 2, 1, 3'b000);
        imem[3]  = enc_i(99, 0, 3'b000, 3, 7'b0010011);
        imem[4]  = enc_b(8, 2, 1, 3'b001);
        imem[5]  = enc_i(7, 0, 3'b000, 3, 7'b0010011);
        imem[6]  = enc_j(8, 4);
        imem[7]  = enc_i(99, 0, 3'b000, 3, 7'b0010011);
        imem[8]  = enc_i(1, 0, 3'b000, 5, 7'b0010011);
        imem[9]  = enc_i(44, 0, 3'b000, 7, 7'b0010011);
        imem[10] = enc_i(4, 7, 3'b000, 6, 7'b1100111);
        imem[11] = enc_i(99, 0, 3'b000, 8, 7'b0010011);
        imem[12] = enc_i(8, 0, 3'b000, 8, 7'b0010011);

        repeat (2) @(negedge clk);
        rst_n = 1;

        repeat (18) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        $display("");
        $display("===== CONTROL-FLOW TEST RESULTS =====");

        check_reg(1, 32'd5);
        check_reg(2, 32'd5);
        check_reg(3, 32'd7);
        check_reg(4, 32'd28);
        check_reg(5, 32'd1);
        check_reg(6, 32'd44);
        check_reg(7, 32'd44);
        check_reg(8, 32'd8);
        check_reg(0, 32'd0);

        $display("Cycles checked: %0d", cycles);
        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("PASS: Control-flow tests passed");
        else
            $display("FAIL: Control-flow tests failed");

        $finish;
    end

endmodule
