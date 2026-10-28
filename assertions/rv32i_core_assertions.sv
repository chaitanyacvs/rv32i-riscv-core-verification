`timescale 1ns/1ps

module rv32i_core_assertions (
    input logic        clk,
    input logic        rst_n,
    input logic [31:0] pc,
    input logic        mem_we,
    input logic [3:0]  mem_wstrb
);

    integer checks_passed = 0;

    // Check that reset brings the program counter to zero.
    always @(negedge clk) begin
        if (!rst_n) begin
            assert (pc == 32'd0)
            else $error("ASSERTION FAILED: PC must be zero during reset");
        end
        else begin
            // RV32I instructions are 32-bit aligned in this implementation.
            assert (pc[1:0] == 2'b00)
            else $error("ASSERTION FAILED: PC is not word aligned");

            // Stores use all four byte lanes in this core.
            if (mem_we) begin
                assert (mem_wstrb == 4'b1111)
                else $error(
                    "ASSERTION FAILED: Store must enable all byte lanes"
                );
            end
            else begin
                assert (mem_wstrb == 4'b0000)
                else $error(
                    "ASSERTION FAILED: Byte strobes must be zero without a store"
                );
            end

            checks_passed = checks_passed + 3;
        end
    end

    final begin
        $display(
            "RV32I assertion checker finished; sampled checks=%0d",
            checks_passed
        );
    end

endmodule
