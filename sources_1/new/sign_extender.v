`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 02:39:26 PM
// Design Name: 
// Module Name: sign_extender
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
//  sign_extender.v  -  16-bit to 32-bit SIGN Extender
//
//  BUG FIX (vs original zero_extender_16_to_32.v):
//  The original file used zero-extension: {16'b0, in}
//  This is WRONG for negative immediates in ADDI, LW, SW, BEQ.
//  True sign-extension replicates the MSB (bit 15) into the
//  upper 16 bits.
//
//  Example:
//    in  = 16'hFFFF  (-1 in two's complement)
//    ZERO ext → 32'h0000FFFF (+65535)  ← WRONG
//    SIGN ext → 32'hFFFFFFFF (-1)      ← CORRECT
// =============================================================

module sign_extender (
    input  wire [15:0] in,   // 16-bit immediate from instruction
    output wire [31:0] out   // 32-bit sign-extended output
);

    assign out = {{16{in[15]}}, in};   // replicate MSB 16 times

endmodule
