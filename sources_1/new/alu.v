`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2026 05:07:17 PM
// Design Name: 
// Module Name: alu
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


// =============================================================
//  ALU Module
//  Operands : s1, s2  - 32-bit each
//  Inputs   : func    - 6-bit function field
//             alu_control - 2-bit signal from control unit
//  Outputs  : result  - 32-bit ALU result
//             equal   - 1-bit equality flag (valid only when alu_control == 2'b01)
// =============================================================
//
//  alu_control truth-table
//  ─────────────────────────────────────────────────────────────
//  2'b00 → use func field
//           func = 6'b100000 : result = s1 + s2
//           func = 6'b100110 : result = s1 ^ s2
//           func = 6'b100010 : result = s1-s2
//           others           : result = 32'bx  (don't care)
//
//  2'b01 → ignore func; compare s1 == s2
//           result = 32'b0 (unused)
//           equal  = 1 if s1 == s2, else 0
//
//  2'b10 → ignore func; result = s1 + s2
//           equal  = 0 (unused)
//
//  2'b11 → don't care
// =============================================================

module alu (
    input  wire [31:0] s1,           // First operand
    input  wire [31:0] s2,           // Second operand
    input  wire [ 5:0] func,         // 6-bit function field
    input  wire [ 1:0] alu_control,  // 2-bit control from CU

    output reg  [31:0] result,       // 32-bit ALU result
    output reg         equal         // 1-bit equality output (alu_control == 01 only)
);

    // ── Function-field parameter definitions ──────────────────
    localparam FUNC_ADD = 6'b100000;   // Addition
    localparam FUNC_XOR = 6'b100110;   // XOR
    localparam FUNC_SUB= 6'b100010;   // SUBTRACTION

    // ── Main combinational block ───────────────────────────────
    always @(*) begin
        // Default outputs to avoid unintended latches
        result = 32'b0;
        equal  = 1'b0;

        case (alu_control)

            // ── 2'b00 : function field decides the operation ──
            2'b00 : begin
                case (func)
                    FUNC_ADD : result = s1 + s2;
                    FUNC_XOR : result = s1 ^ s2;
                    FUNC_SUB : result = s1-s2;
                    default  : result = 32'bx;           // don't care
                endcase
                equal = 1'b0;   // not meaningful here
            end

            // ── 2'b01 : compare s1 and s2 ────────────────────
            2'b01 : begin
                result = 32'b0;                          // result bus unused
                equal  = (s1 == s2) ? 1'b1 : 1'b0;
            end

            // ── 2'b10 : unconditional add ─────────────────────
            2'b10 : begin
                result = s1 + s2;
                equal  = 1'b0;  // not meaningful here
            end

            // ── 2'b11 : don't care ────────────────────────────
            2'b11 : begin
                result = 32'bx;
                equal  = 1'bx;
            end

            default : begin
                result = 32'bx;
                equal  = 1'bx;
            end
        endcase
    end

endmodule
