`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2026 02:32:15 PM
// Design Name: 
// Module Name: cpu_top
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
//  cpu_top.v  -  32-bit Single-Cycle MIPS-inspired CPU
//
//  Author  : (your name)
//  Date    : 2026-06-28
//
//  This file is a pure structural wrapper.
//  It contains NO logic - only wires and module instantiations.
//
//  ISA supported
//  ─────────────
//  R-type : ADD, SUB, XOR
//  I-type : ADDI, LW, SW, BEQ
//  J-type : JUMP
//
//  Datapath overview
//  ─────────────────
//
//   ┌──PC──►InstMem──►[IR]──────────────────────────────────────┐
//   │                  │  [31:26] opcode ──► ControlUnit         │
//   │                  │  [25:21] rs     ──► RegFile.Read_Reg1   │
//   │                  │  [20:16] rt     ──► RegFile.Read_Reg2   │
//   │                  │  [15:11] rd  ─┐                         │
//   │                  │  [15:0] imm ──► SignExt ──► ALU src2    │
//   │                  │  [25:0] target─► JumpTarget             │
//   │                                                            │
//   │  PC+4 ──► BranchAdder ──► BranchMux ──► JumpMux ──► PC   │
//   └───────────────────────────────────────────────────────────┘
//
// =============================================================

module cpu_top (
    input  wire clk,
    input  wire reset
);

    // =========================================================
    // 1.  INTERNAL WIRE DECLARATIONS
    // =========================================================

    // -- Program Counter -----------------------------------
    wire [31:0] pc_current;          // Current PC value
    wire [31:0] pc_plus4;            // PC + 4
    wire [31:0] pc_next;             // Feed back into PC

    // -- Instruction fields --------------------------------
    wire [31:0] instruction;         // Raw 32-bit instruction
    wire [ 5:0] opcode;              // instruction[31:26]
    wire [ 4:0] rs, rt, rd;          // Register specifiers
    wire [ 5:0] funct;               // instruction[5:0]
    wire [15:0] imm16;               // Immediate field
    wire [25:0] jump_target_raw;     // instruction[25:0]

    // -- Control signals -----------------------------------
    wire        RegDst;   // 0→rt, 1→rd is write destination
    wire        Jump;     // 1 = take jump
    wire        Branch;   // 1 = BEQ active
    wire        MemRead;  // 1 = data memory read
    wire        MemToReg; // 0→ALU result, 1→memory read data
    wire [1:0]  ALUOp;    // to ALU Decoder (re-used as alu_control)
    wire        MemWrite; // 1 = data memory write
    wire        ALUSrc;   // 0→rt, 1→sign-extended immediate
    wire        RegWrite; // 1 = write to register file

    // -- Register file -------------------------------------
    wire [4:0]  write_reg;           // Selected write address (rd or rt)
    wire [31:0] read_data1;          // rs value
    wire [31:0] read_data2;          // rt value
    wire [31:0] reg_write_data;      // Data written back to register

    // -- Sign extension ------------------------------------
    wire [31:0] sign_ext_imm;        // 16-bit imm sign-extended to 32

    // -- ALU -----------------------------------------------
    wire [31:0] alu_src2;            // Second ALU operand (mux output)
    wire [31:0] alu_result;          // ALU arithmetic/logic result
    wire        alu_equal;           // 1 if s1 == s2  (used by BEQ)

    // -- Branch / Jump address computation -----------------
    wire [31:0] branch_target;       // PC+4 + (sign_ext_imm << 2)
    wire [31:0] pc_branch_mux_out;   // After BEQ mux
    wire [31:0] jump_target_addr;    // Full 32-bit jump address
    wire        branch_taken;        // Branch AND equal

    // -- Data memory ---------------------------------------
    wire [31:0] mem_read_data;       // Data loaded from memory

    // -- Adder overflow (unused but must be connected) -----
    wire        pc_adder_overflow;
    wire        branch_adder_overflow;

    // =========================================================
    // 2.  INSTRUCTION FIELD EXTRACTION  (combinational slices)
    // =========================================================
    assign opcode          = instruction[31:26];
    assign rs              = instruction[25:21];
    assign rt              = instruction[20:16];
    assign rd              = instruction[15:11];
    assign funct           = instruction[5:0];
    assign imm16           = instruction[15:0];
    assign jump_target_raw = instruction[25:0];

    // =========================================================
    // 3.  PROGRAM COUNTER
    // =========================================================
    program_counter u_pc (
        .clk        (clk),
        .reset      (reset),
        .pc_next    (pc_next),
        .pc_current (pc_current)
    );

    // =========================================================
    // 4.  PC + 4  ADDER
    // =========================================================
    adder_32bit u_pc4_adder (
        .A        (pc_current),
        .B        (32'd4),
        .SUM      (pc_plus4),
        .overflow (pc_adder_overflow)
    );

    // =========================================================
    // 5.  INSTRUCTION MEMORY
    // =========================================================
    instruction_memory u_imem (
        .Address     (pc_current),
        .Instruction (instruction)
    );

    // =========================================================
    // 6.  CONTROL UNIT
    // =========================================================
    control_unit u_ctrl (
        .opcode   (opcode),
        .RegDst   (RegDst),
        .Jump     (Jump),
        .Branch   (Branch),
        .MemRead  (MemRead),
        .MemToReg (MemToReg),
        .ALUOp    (ALUOp),
        .MemWrite (MemWrite),
        .ALUSrc   (ALUSrc),
        .RegWrite (RegWrite)
    );

    // =========================================================
    // 7.  REGISTER DESTINATION MUX  (RegDst: 0→rt, 1→rd)
    // =========================================================
    // NOTE: mux.v is 1-bit only; for 5-bit we use a simple assign.
    assign write_reg = (RegDst == 1'b0) ? rt : rd;

    // =========================================================
    // 8.  REGISTER FILE
    // =========================================================
    register_bank u_regfile (
        .clk        (clk),
        .RegWrite   (RegWrite),
        .Read_Reg1  (rs),
        .Read_Reg2  (rt),
        .Write_Reg  (write_reg),
        .Write_Data (reg_write_data),
        .Read_Data1 (read_data1),
        .Read_Data2 (read_data2)
    );

    // =========================================================
    // 9.  SIGN EXTENDER  (16 → 32, ARITHMETIC)
    //     NOTE: the uploaded file does ZERO extension.
    //     We override with an inline assign here for correctness.
    //     See review notes in the companion document.
    // =========================================================
    assign sign_ext_imm = {{16{imm16[15]}}, imm16};   // true sign-extension

    // =========================================================
    // 10. ALU SOURCE MUX  (ALUSrc: 0→rd2, 1→sign_ext_imm)
    // =========================================================
    assign alu_src2 = (ALUSrc == 1'b0) ? read_data2 : sign_ext_imm;

    // =========================================================
    // 11. ALU
    // =========================================================
    alu u_alu (
        .s1          (read_data1),
        .s2          (alu_src2),
        .func        (funct),
        .alu_control (ALUOp),        // 2-bit from control unit
        .result      (alu_result),
        .equal       (alu_equal)
    );

    // =========================================================
    // 12. BRANCH TARGET ADDER  (PC+4 + sign_ext_imm<<2)
    // =========================================================
    adder_32bit u_branch_adder (
        .A        (pc_plus4),
        .B        (sign_ext_imm << 2),   // left-shift by 2 (word align)
        .SUM      (branch_target),
        .overflow (branch_adder_overflow)
    );

    // =========================================================
    // 13. BRANCH CONDITION
    // =========================================================
    assign branch_taken = Branch & alu_equal;

    // =========================================================
    // 14. BRANCH MUX  (branch_taken: 0→PC+4, 1→branch_target)
    // =========================================================
    assign pc_branch_mux_out = (branch_taken == 1'b0) ? pc_plus4 : branch_target;

    // =========================================================
    // 15. JUMP TARGET ADDRESS
    //     MIPS spec: {PC+4[31:28], target[25:0], 2'b00}
    // =========================================================
    assign jump_target_addr = {pc_plus4[31:28], jump_target_raw, 2'b00};

    // =========================================================
    // 16. JUMP MUX  (Jump: 0→branch_mux_out, 1→jump_target)
    // =========================================================
    assign pc_next = (Jump == 1'b0) ? pc_branch_mux_out : jump_target_addr;

    // =========================================================
    // 17. DATA MEMORY
    // =========================================================
    data_memory u_dmem (
        .clk        (clk),
        .MemWrite   (MemWrite),
        .MemRead    (MemRead),
        .Address    (alu_result),
        .Write_Data (read_data2),
        .Read_Data  (mem_read_data)
    );

    // =========================================================
    // 18. WRITE-BACK MUX  (MemToReg: 0→ALU result, 1→mem data)
    // =========================================================
    assign reg_write_data = (MemToReg == 1'b0) ? alu_result : mem_read_data;

endmodule