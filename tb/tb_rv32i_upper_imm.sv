`timescale 1ns/1ps

module tb_rv32i_upper_imm;

    logic clk = 0;
    logic rst_n = 0;
    logic [31:0] pc, instr;
    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    logic [3:0] mem_wstrb;
    logic mem_we;

    logic [31:0] imem [0:15];
    logic [31:0] data_mem [0:63];
    integer errors = 0;

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

    function automatic [31:0] enc_u(
        input integer imm20,
        input integer rd_i,
        input integer opcode_i
    );
        enc_u = {imm20[19:0], rd_i[4:0], opcode_i[6:0]};
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

        // LUI x1, 0x12345 -> 0x12345000
        imem[0] = enc_u(20'h12345, 1, 7'b0110111);

        // AUIPC x2, 0x00002 at PC=4 -> 0x00002004
        imem[1] = enc_u(20'h00002, 2, 7'b0010111);

        // LUI x3, 0xFFFFF -> 0xFFFFF000
        imem[2] = enc_u(20'hFFFFF, 3, 7'b0110111);

        // AUIPC x4, 0x00001 at PC=12 -> 0x0000100C
        imem[3] = enc_u(20'h00001, 4, 7'b0010111);

        repeat (2) @(negedge clk);
        rst_n = 1;

        repeat (8) @(negedge clk);
        #1;

        $display("");
        $display("===== LUI / AUIPC RESULTS =====");

        check_reg(1, 32'h12345000);
        check_reg(2, 32'h00002004);
        check_reg(3, 32'hFFFFF000);
        check_reg(4, 32'h0000100C);
        check_reg(0, 32'h00000000);

        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("PASS: LUI/AUIPC tests passed");
        else
            $display("FAIL: LUI/AUIPC tests failed");

        $finish;
    end

endmodule
