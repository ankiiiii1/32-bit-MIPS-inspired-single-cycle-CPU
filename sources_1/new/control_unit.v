`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2026 02:29:02 PM
// Design Name: 
// Module Name: control_unit
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


`timescale 1ns / 1ps
// =============================================================
//  control_unit.v  -  Main Control Unit
//
//  Decodes the 6-bit opcode from the instruction register and
//  drives all datapath control signals.
//
//  Opcode table (from your ISA notes)
//  ────────────────────────────────────────────────────────────
//  Opcode    Instruction   RegDst Jump Branch MemRead MemToReg
//                          ALUOp  MemWrite ALUSrc  RegWrite
//  ────────────────────────────────────────────────────────────
//  000000    R-type         1  0  0  0  0  00  0  0  1
//  100011    LW             0  0  0  1  1  11  0  1  1
//  101011    SW             x  0  0  0  x  11  1  0  0   (RegDst/MemToReg don't matter)
//  000100    BEQ            x  0  1  0  0  01  0  0  0
//  001000    ADDI           0  0  0  0  0  10  0  1  1
//  000010    JUMP           x  1  0  0  0  xx  0  0  0
//
//  ALUOp encoding (feeds directly into alu_control port)
//  ──────────────────────────────────────────────────────
//  2'b00 → R-type  (funct field decides operation)
//  2'b01 → BEQ     (compare / subtract)
//  2'b10 → ADD     (ADDI, LW, SW  - always add for address calc)
//  2'b11 → don't care
// =============================================================

module control_unit (
    input  wire [5:0] opcode,

    output reg        RegDst,    // 0 = write to rt, 1 = write to rd
    output reg        Jump,      // 1 = unconditional jump
    output reg        Branch,    // 1 = BEQ branch condition active
    output reg        MemRead,   // 1 = read from data memory (LW)
    output reg        MemToReg,  // 0 = ALU result, 1 = memory read data
    output reg [1:0]  ALUOp,     // selects ALU operation class
    output reg        MemWrite,  // 1 = write to data memory (SW)
    output reg        ALUSrc,    // 0 = register, 1 = sign-extended immediate
    output reg        RegWrite   // 1 = write result back to register file
);

    // Opcode parameters
    localparam OP_RTYPE = 6'b000000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_BEQ   = 6'b000100;
    localparam OP_ADDI  = 6'b001000;
    localparam OP_JUMP  = 6'b000010;

    always @(*) begin
        // Safe defaults - prevent accidental latches
        RegDst   = 1'b0;
        Jump     = 1'b0;
        Branch   = 1'b0;
        MemRead  = 1'b0;
        MemToReg = 1'b0;
        ALUOp    = 2'b10;   // default: add  (safe for unrecognised ops)
        MemWrite = 1'b0;
        ALUSrc   = 1'b0;
        RegWrite = 1'b0;

        case (opcode)

            // ── R-type ────────────────────────────────────────
            OP_RTYPE : begin
                RegDst   = 1'b1;   // destination = rd
                Jump     = 1'b0;
                Branch   = 1'b0;
                MemRead  = 1'b0;
                MemToReg = 1'b0;   // write ALU result to register
                ALUOp    = 2'b00;  // let funct field decide
                MemWrite = 1'b0;
                ALUSrc   = 1'b0;   // second source = rt
                RegWrite = 1'b1;
            end

            // ── Load Word ─────────────────────────────────────
            OP_LW : begin
                RegDst   = 1'b0;   // destination = rt
                Jump     = 1'b0;
                Branch   = 1'b0;
                MemRead  = 1'b1;
                MemToReg = 1'b1;   // write memory data to register
                ALUOp    = 2'b10;  // add  (base + offset)
                MemWrite = 1'b0;
                ALUSrc   = 1'b1;   // second source = immediate
                RegWrite = 1'b1;
            end

            // ── Store Word ────────────────────────────────────
            OP_SW : begin
                RegDst   = 1'b0;   // don't care, but tie low
                Jump     = 1'b0;
                Branch   = 1'b0;
                MemRead  = 1'b0;
                MemToReg = 1'b0;   // don't care
                ALUOp    = 2'b10;  // add  (base + offset)
                MemWrite = 1'b1;
                ALUSrc   = 1'b1;   // second source = immediate
                RegWrite = 1'b0;
            end

            // ── Branch on Equal ───────────────────────────────
            OP_BEQ : begin
                RegDst   = 1'b0;   // don't care
                Jump     = 1'b0;
                Branch   = 1'b1;   // signal branch logic
                MemRead  = 1'b0;
                MemToReg = 1'b0;   // don't care
                ALUOp    = 2'b01;  // compare (s1 == s2)
                MemWrite = 1'b0;
                ALUSrc   = 1'b0;   // compare rt, not immediate
                RegWrite = 1'b0;
            end

            // ── Add Immediate ─────────────────────────────────
            OP_ADDI : begin
                RegDst   = 1'b0;   // destination = rt
                Jump     = 1'b0;
                Branch   = 1'b0;
                MemRead  = 1'b0;
                MemToReg = 1'b0;   // write ALU result to register
                ALUOp    = 2'b10;  // always add
                MemWrite = 1'b0;
                ALUSrc   = 1'b1;   // second source = immediate
                RegWrite = 1'b1;
            end

            // ── Jump ──────────────────────────────────────────
            OP_JUMP : begin
                RegDst   = 1'b0;   // don't care
                Jump     = 1'b1;   // override PC with jump target
                Branch   = 1'b0;
                MemRead  = 1'b0;
                MemToReg = 1'b0;   // don't care
                ALUOp    = 2'b10;  // don't care
                MemWrite = 1'b0;
                ALUSrc   = 1'b0;   // don't care
                RegWrite = 1'b0;
            end

            // ── Default (safety) ──────────────────────────────
            default : begin
                RegDst   = 1'b0;
                Jump     = 1'b0;
                Branch   = 1'b0;
                MemRead  = 1'b0;
                MemToReg = 1'b0;
                ALUOp    = 2'b10;
                MemWrite = 1'b0;
                ALUSrc   = 1'b0;
                RegWrite = 1'b0;
            end

        endcase
    end

endmodule
