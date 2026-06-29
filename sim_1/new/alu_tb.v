`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/23/2026 05:09:46 PM
// Design Name: 
// Module Name: alu_tb
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
//  Testbench for ALU module
// =============================================================
`timescale 1ns/1ps

module alu_tb;

    // ── DUT inputs ────────────────────────────────────────────
    reg  [31:0] s1, s2;
    reg  [ 5:0] func;
    reg  [ 1:0] alu_control;

    // ── DUT outputs ───────────────────────────────────────────
    wire [31:0] result;
    wire        equal;

    // ── Instantiate DUT ───────────────────────────────────────
    alu dut (
        .s1          (s1),
        .s2          (s2),
        .func        (func),
        .alu_control (alu_control),
        .result      (result),
        .equal       (equal)
    );

    // ── Helper task ───────────────────────────────────────────
    task apply;
        input [31:0] a, b;
        input [ 5:0] f;
        input [ 1:0] ctrl;
        begin
            s1 = a; s2 = b; func = f; alu_control = ctrl;
            #10;
        end
    endtask

    // ── Stimulus ──────────────────────────────────────────────
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        $display("=================================================");
        $display(" ALU Testbench");
        $display("=================================================");
        $display("Time | alu_ctrl | func   | s1         | s2         | result     | equal");

        // ── alu_control = 00 : ADD  (func = 100000) ──────────
        apply(32'd15, 32'd10, 6'b100000, 2'b00);
        $display("%4t |    00    | 100000 | %10d | %10d | %10d | %b   [expect result=25]",
                 $time, s1, s2, result, equal);

        // ── alu_control = 00 : XOR  (func = 100110) ──────────
        apply(32'hA5A5A5A5, 32'h5A5A5A5A, 6'b100110, 2'b00);
        $display("%4t |    00    | 100110 | %10h | %10h | %10h | %b   [expect result=FFFFFFFF]",
                 $time, s1, s2, result, equal);

        // ── alu_control = 00 : SLL  (func = 000000) ──────────
        apply(32'd1, 32'd4, 6'b000000, 2'b00);
        $display("%4t |    00    | 000000 | %10d | %10d | %10d | %b   [expect result=16]",
                 $time, s1, s2, result, equal);

        // ── alu_control = 01 : EQUAL (s1 == s2) ──────────────
        apply(32'd42, 32'd42, 6'bxxxxxx, 2'b01);
        $display("%4t |    01    |  x     | %10d | %10d | %10d | %b   [expect equal=1]",
                 $time, s1, s2, result, equal);

        // ── alu_control = 01 : NOT EQUAL ─────────────────────
        apply(32'd42, 32'd99, 6'bxxxxxx, 2'b01);
        $display("%4t |    01    |  x     | %10d | %10d | %10d | %b   [expect equal=0]",
                 $time, s1, s2, result, equal);

        // ── alu_control = 10 : Force ADD ─────────────────────
        apply(32'd100, 32'd200, 6'b000000, 2'b10);  // func is SLL but must be ignored
        $display("%4t |    10    | 000000 | %10d | %10d | %10d | %b   [expect result=300, func ignored]",
                 $time, s1, s2, result, equal);

        // ── alu_control = 11 : don't care ─────────────────────
        apply(32'd5, 32'd5, 6'b100000, 2'b11);
        $display("%4t |    11    | 100000 | %10d | %10d | %10d | %b   [don't care]",
                 $time, s1, s2, result, equal);

        $display("=================================================");
        $display(" Simulation complete.");
        $display("=================================================");
        $finish;
    end

endmodule