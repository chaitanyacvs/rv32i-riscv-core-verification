`timescale 1ns/1ps

module tb_rv32i_core;
    logic clk = 0;
    logic rst_n = 0;

    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    logic [3:0] mem_wstrb;
    logic mem_we;

    // "program" is a SystemVerilog keyword, so use imem instead.
    logic [31:0] imem [0:15];
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

    // Combinational instruction and data memory.
    always @(*) begin
        if ((pc[31:2] < 16) && (pc[1:0] == 2'b00))
            instr = imem[pc[5:2]];
        else
            instr = 32'h00000013; // NOP

        mem_rdata = data_mem[mem_addr[7:2]];
    end

    // Simplified word-store memory model.
    always @(posedge clk) begin
        if (rst_n && mem_we)
            data_mem[mem_addr[7:2]] <= mem_wdata;
    end

    // Encode an I-type instruction.
    function automatic [31:0] enc_i(
        input integer imm_i,
        input integer rs1_i,
        input integer funct3_i,
        input integer rd_i,
        input integer opcode_i
    );
        enc_i = {
            imm_i[11:0],
            rs1_i[4:0],
            funct3_i[2:0],
            rd_i[4:0],
            opcode_i[6:0]
        };
    endfunction

    // Encode an R-type instruction.
    function automatic [31:0] enc_r(
        input integer funct7_i,
        input integer rs2_i,
        input integer rs1_i,
        input integer funct3_i,
        input integer rd_i,
        input integer opcode_i
    );
        enc_r = {
            funct7_i[6:0],
            rs2_i[4:0],
            rs1_i[4:0],
            funct3_i[2:0],
            rd_i[4:0],
            opcode_i[6:0]
        };
    endfunction

    // Encode an S-type instruction.
    function automatic [31:0] enc_s(
        input integer imm_s,
        input integer rs2_i,
        input integer rs1_i,
        input integer funct3_i,
        input integer opcode_i
    );
        enc_s = {
            imm_s[11:5],
            rs2_i[4:0],
            rs1_i[4:0],
            funct3_i[2:0],
            imm_s[4:0],
            opcode_i[6:0]
        };
    endfunction

    initial begin
        // Initialize instruction and data memories.
        for (integer j = 0; j < 16; j = j + 1)
            imem[j] = 32'h00000013;

        for (integer k = 0; k < 64; k = k + 1)
            data_mem[k] = 32'd0;

        // Program:
        // x1 = 5
        // x2 = 7
        // x3 = x1 + x2 = 12
        // x4 = x3 XOR x1 = 9
        // data_mem[0] = x3
        // x5 = data_mem[0] = 12
        // x6 = x1 - x2 = -2

        imem[0] = enc_i(5, 0, 3'b000, 1, 7'b0010011);
        imem[1] = enc_i(7, 0, 3'b000, 2, 7'b0010011);
        imem[2] = enc_r(0, 2, 1, 3'b000, 3, 7'b0110011);
        imem[3] = enc_r(0, 1, 3, 3'b100, 4, 7'b0110011);
        imem[4] = enc_s(0, 3, 0, 3'b010, 7'b0100011);
        imem[5] = enc_i(0, 0, 3'b010, 5, 7'b0000011);
        imem[6] = enc_r(7'b0100000, 2, 1, 3'b000, 6, 7'b0110011);
        imem[7] = 32'h00000013;

        // Hold reset for two rising clock edges.
        repeat (2) @(negedge clk);
        rst_n = 1;

        // Allow the program to execute.
        repeat (10) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        // Check register and memory results.
        if (dut.regs[1] !== 32'd5) begin
            $display("FAIL x1: expected 5, got %h", dut.regs[1]);
            errors = errors + 1;
        end

        if (dut.regs[2] !== 32'd7) begin
            $display("FAIL x2: expected 7, got %h", dut.regs[2]);
            errors = errors + 1;
        end

        if (dut.regs[3] !== 32'd12) begin
            $display("FAIL x3: expected 12, got %h", dut.regs[3]);
            errors = errors + 1;
        end

        if (dut.regs[4] !== 32'd9) begin
            $display("FAIL x4: expected 9, got %h", dut.regs[4]);
            errors = errors + 1;
        end

        if (data_mem[0] !== 32'd12) begin
            $display("FAIL data_mem[0]: expected 12, got %h", data_mem[0]);
            errors = errors + 1;
        end

        if (dut.regs[5] !== 32'd12) begin
            $display("FAIL x5: expected 12, got %h", dut.regs[5]);
            errors = errors + 1;
        end

        if (dut.regs[6] !== 32'hFFFFFFFE) begin
            $display("FAIL x6: expected FFFFFFFE, got %h", dut.regs[6]);
            errors = errors + 1;
        end

        if (dut.regs[0] !== 32'd0) begin
            $display("FAIL x0: must remain zero, got %h", dut.regs[0]);
            errors = errors + 1;
        end

        $display("");
        $display("========== RV32I VERIFICATION SUMMARY ==========");
        $display("Cycles checked: %0d", cycles);
        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("PASS: RV32I starter tests passed");
        else
            $display("FAIL: RV32I starter tests failed");

        $display("================================================");
        $finish;
    end

endmodule
