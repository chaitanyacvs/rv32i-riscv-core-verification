`timescale 1ns/1ps

module rv32i_core (
    input  logic        clk,
    input  logic        rst_n,

    output logic [31:0] pc,
    input  logic [31:0] instr,

    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    output logic [3:0]  mem_wstrb,
    output logic        mem_we,
    input  logic [31:0] mem_rdata
);

    logic [31:0] regs [0:31];
    logic [31:0] next_pc;
    logic [31:0] imm;
    logic [31:0] rs1_value, rs2_value;
    logic [31:0] alu_a, alu_b, alu_result;
    logic [31:0] writeback_value;
    logic [4:0] rd, rs1, rs2;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic reg_write;
    logic [3:0] alu_op;
    logic branch_taken;
    logic [31:0] pc_plus4;

    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_SLL  = 4'd5;
    localparam ALU_SRL  = 4'd6;
    localparam ALU_SRA  = 4'd7;
    localparam ALU_SLT  = 4'd8;
    localparam ALU_SLTU = 4'd9;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    assign rs1_value = (rs1 == 0) ? 32'd0 : regs[rs1];
    assign rs2_value = (rs2 == 0) ? 32'd0 : regs[rs2];

    assign pc_plus4 = pc + 32'd4;
    assign alu_a = rs1_value;
    assign alu_b = ((opcode == 7'b0010011) ||
                    (opcode == 7'b0000011) ||
                    (opcode == 7'b0100011)) ? imm : rs2_value;

    always_comb begin
        imm = 32'd0;
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111:
                imm = {{20{instr[31]}}, instr[31:20]};
            7'b0100011:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011:
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};
            7'b0110111, 7'b0010111:
                imm = {instr[31:12], 12'd0};
            7'b1101111:
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};
            default: imm = 32'd0;
        endcase
    end

    always_comb begin
        alu_op = ALU_ADD;
        case (opcode)
            7'b0110011, 7'b0010011: begin
                case (funct3)
                    3'b000: alu_op = (funct7[5] && opcode == 7'b0110011)
                                     ? ALU_SUB : ALU_ADD;
                    3'b111: alu_op = ALU_AND;
                    3'b110: alu_op = ALU_OR;
                    3'b100: alu_op = ALU_XOR;
                    3'b001: alu_op = ALU_SLL;
                    3'b101: alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    default: alu_op = ALU_ADD;
                endcase
            end
            7'b1100011: alu_op = ALU_SUB;
            default: alu_op = ALU_ADD;
        endcase
    end

    always_comb begin
        case (alu_op)
            ALU_ADD:  alu_result = alu_a + alu_b;
            ALU_SUB:  alu_result = alu_a - alu_b;
            ALU_AND:  alu_result = alu_a & alu_b;
            ALU_OR:   alu_result = alu_a | alu_b;
            ALU_XOR:  alu_result = alu_a ^ alu_b;
            ALU_SLL:  alu_result = alu_a << alu_b[4:0];
            ALU_SRL:  alu_result = alu_a >> alu_b[4:0];
            ALU_SRA:  alu_result = $signed(alu_a) >>> alu_b[4:0];
            ALU_SLT:  alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result = (alu_a < alu_b) ? 32'd1 : 32'd0;
            default:  alu_result = 32'd0;
        endcase
    end

    always_comb begin
        next_pc = pc_plus4;
        branch_taken = 1'b0;

        case (opcode)
            7'b1100011: begin
                case (funct3)
                    3'b000: branch_taken = (rs1_value == rs2_value); // BEQ
                    3'b001: branch_taken = (rs1_value != rs2_value); // BNE
                    default: branch_taken = 1'b0;
                endcase
                if (branch_taken)
                    next_pc = pc + imm;
            end
            7'b1101111: next_pc = pc + imm; // JAL
            7'b1100111: next_pc = (rs1_value + imm) & 32'hFFFF_FFFE; // JALR
            default: next_pc = pc_plus4;
        endcase
    end

    always_comb begin
        mem_addr = alu_result;
        mem_wdata = rs2_value;
        mem_wstrb = 4'b0000;
        mem_we = 1'b0;
        reg_write = 1'b0;
        writeback_value = alu_result;

        case (opcode)
            7'b0110011, 7'b0010011, 7'b0110111, 7'b0010111:
                reg_write = 1'b1;
            7'b0000011: begin // LW
                reg_write = 1'b1;
                writeback_value = mem_rdata;
            end
            7'b0100011: begin // SW
                mem_we = 1'b1;
                mem_wstrb = 4'b1111;
            end
            7'b1101111, 7'b1100111: begin
                reg_write = 1'b1;
                writeback_value = pc_plus4;
            end
            default: reg_write = 1'b0;
        endcase

        if (opcode == 7'b0110111)
            writeback_value = imm;             // LUI
        else if (opcode == 7'b0010111)
            writeback_value = pc + imm;        // AUIPC
    end

    integer r;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'd0;
            for (r = 0; r < 32; r = r + 1)
                regs[r] <= 32'd0;
        end else begin
            pc <= next_pc;
            if (reg_write && (rd != 0))
                regs[rd] <= writeback_value;
            regs[0] <= 32'd0;
        end
    end

endmodule