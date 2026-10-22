`timescale 1ns/1ps

module tb_rv32i_extended;

    logic clk = 0;
    logic rst_n = 0;
    logic [31:0] pc, instr;
    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    logic [3:0] mem_wstrb;
    logic mem_we;

    logic [31:0] imem [0:31];
    logic [31:0] data_mem [0:63];

    integer errors = 0;
    integer cycles = 0;

    always #5 clk = ~clk;

    rv32i_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .instr(instr),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_we(mem_we),
        .mem_rdata(mem_rdata)
    );

    always @(*) begin
        if ((pc[31:2] < 32) && (pc[1:0] == 0))
            instr = imem[pc[6:2]];
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

    function automatic [31:0] enc_r(
        input integer funct7_i,
        input integer rs2_i,
        input integer rs1_i,
        input integer funct3_i,
        input integer rd_i,
        input integer opcode_i
    );
        enc_r = {
            funct7_i[6:0], rs2_i[4:0], rs1_i[4:0],
            funct3_i[2:0], rd_i[4:0], opcode_i[6:0]
        };
    endfunction

    task automatic check_reg(
        input integer reg_num,
        input logic [31:0] expected
    );
        begin
            if (dut.regs[reg_num] !== expected) begin
                $display(
                    "FAIL x%0d: expected %h, got %h",
                    reg_num, expected, dut.regs[reg_num]
                );
                errors = errors + 1;
            end else begin
                $display("PASS x%0d = %h", reg_num, expected);
            end
        end
    endtask

    initial begin
        for (integer i = 0; i < 32; i = i + 1)
            imem[i] = 32'h00000013;

        for (integer j = 0; j < 64; j = j + 1)
            data_mem[j] = 32'd0;

        // Register setup
        imem[0]  = enc_i(-8, 0, 3'b000, 1, 7'b0010011); // x1 = -8
        imem[1]  = enc_i(3,  0, 3'b000, 2, 7'b0010011); // x2 = 3
        imem[2]  = enc_i(10, 0, 3'b000, 3, 7'b0010011); // x3 = 10

        // R-type arithmetic and logic
        imem[3]  = enc_r(0, 2, 3, 3'b000, 4, 7'b0110011); // ADD: 13
        imem[4]  = enc_r(7'b0100000, 2, 3, 3'b000, 5, 7'b0110011); // SUB: 7
        imem[5]  = enc_r(0, 2, 3, 3'b111, 6, 7'b0110011); // AND: 2
        imem[6]  = enc_r(0, 2, 3, 3'b110, 7, 7'b0110011); // OR: 11
        imem[7]  = enc_r(0, 2, 3, 3'b100, 8, 7'b0110011); // XOR: 9

        // Shift operations
        imem[8]  = enc_i(3,   2, 3'b001, 9,  7'b0010011); // SLLI: 24
        imem[9]  = enc_i(1,   3, 3'b101, 10, 7'b0010011); // SRLI: 5
        imem[10] = enc_i(12'h402, 1, 3'b101, 11, 7'b0010011); // SRAI: -2

        // Signed and unsigned comparisons
        imem[11] = enc_r(0, 2, 1, 3'b010, 12, 7'b0110011); // SLT: 1
        imem[12] = enc_r(0, 2, 1, 3'b011, 13, 7'b0110011); // SLTU: 0

        // Immediate logical and comparison instructions
        imem[13] = enc_i(6, 3, 3'b111, 14, 7'b0010011); // ANDI: 2
        imem[14] = enc_i(5, 3, 3'b110, 15, 7'b0010011); // ORI: 15
        imem[15] = enc_i(6, 3, 3'b100, 16, 7'b0010011); // XORI: 12
        imem[16] = enc_i(2, 3, 3'b101, 17, 7'b0010011); // SRLI: 2
        imem[17] = enc_i(0, 1, 3'b010, 18, 7'b0010011); // SLTI: 1
        imem[18] = enc_i(0, 1, 3'b011, 19, 7'b0010011); // SLTIU: 0
        imem[19] = enc_i(1, 0, 3'b000, 20, 7'b0010011); // x20 = 1
        imem[20] = enc_r(0, 20, 0, 3'b000, 0, 7'b0110011); // Attempt write x0
        imem[21] = 32'h00000013; // NOP

        repeat (2) @(negedge clk);
        rst_n = 1;

        repeat (24) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        #1;
        $display("");
        $display("===== EXTENDED RV32I TEST RESULTS =====");

        check_reg(1,  32'hfffffff8);
        check_reg(2,  32'd3);
        check_reg(3,  32'd10);
        check_reg(4,  32'd13);
        check_reg(5,  32'd7);
        check_reg(6,  32'd2);
        check_reg(7,  32'd11);
        check_reg(8,  32'd9);
        check_reg(9,  32'd24);
        check_reg(10, 32'd5);
        check_reg(11, 32'hfffffffe);
        check_reg(12, 32'd1);
        check_reg(13, 32'd0);
        check_reg(14, 32'd2);
        check_reg(15, 32'd15);
        check_reg(16, 32'd12);
        check_reg(17, 32'd2);
        check_reg(18, 32'd1);
        check_reg(19, 32'd0);
        check_reg(20, 32'd1);
        check_reg(0,  32'd0);

        $display("Cycles checked: %0d", cycles);
        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("PASS: Extended RV32I tests passed");
        else
            $display("FAIL: Extended RV32I tests failed");

        $finish;
    end

endmodule