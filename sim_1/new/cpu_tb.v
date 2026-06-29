`timescale 1ns / 1ps
// ================================================================
//  cpu_tb.v  - v4  CYCLE-EXACT (derived from actual simulation trace)
//
//  GROUND TRUTH from debug run:
//  Cycle | PC     | Event
//  ──────────────────────────────────────────────────────────────
//    1   | 0x00   | reset=1, ADDI $1 combinationally active
//    2   | 0x00   | reset=1
//    3   | 0x04   | reset just released (reset=0 set before posedge 3)
//    4   | 0x08   | R2=20 written  (ADDI $2)
//    5   | 0x0C   | R3 written     (ADDI $3,-5)
//    6   | 0x10   | R4=30 written  (ADD)
//    7   | 0x14   | R5=10 written  (SUB)
//    8   | 0x18   | R6=30 written  (XOR)
//    9   | 0x1C   | MEM[0]=30 written (SW $4)
//   10   | 0x20   | MEM[4]=10 written (SW $5)
//   11   | 0x24   | R7=30 written  (LW $7)
//   12   | 0x28   | R8=10 written  (LW $8)
//   13   | 0x2C   | BEQ not-taken resolved  ← check PC=0x2C here
//   14   | 0x30   | R1=11 written (ADDI $1,$1,1)  ← check R1 here
//   15   | 0x38   | BEQ taken resolved  ← check PC=0x38 here
//   16   | 0x00   | JUMP resolved  ← check PC=0x00 here
//
//  NOTE on R1: reset=1 during cycles 1-2, but ADDI at addr 0 is
//  combinationally active (imem reads PC=0 even during reset).
//  The register write for ADDI $1 happens at the posedge that
//  releases reset (cycle 3 posedge). So R1=10 appears at cycle 3
//  onward. We just check it at cycle 3 or later -- it's fine.
// ================================================================

module cpu_tb;

    reg clk;
    reg reset;

    cpu_top dut (.clk(clk), .reset(reset));

    initial clk = 0;
    always  #5 clk = ~clk;

    `define REG(n) dut.u_regfile.registers[n]
    `define MEM(n) dut.u_dmem.dmem[n]

    integer pass_count;
    integer fail_count;

    initial begin #600; $display("WATCHDOG"); $finish; end

    // ── tasks ─────────────────────────────────────────────────────
    task check_reg;
        input [4:0]    rnum;
        input [31:0]   exp;
        input [30*8:1] lbl;
        begin
            if (`REG(rnum) === exp) begin
                $display("  PASS | %-22s | $%0d = %0d", lbl, rnum, $signed(exp));
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-22s | $%0d  exp=%0d  got=%0d",
                    lbl, rnum, $signed(exp), $signed(`REG(rnum)));
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_mem;
        input [7:0]    widx;
        input [31:0]   exp;
        input [30*8:1] lbl;
        begin
            if (`MEM(widx) === exp) begin
                $display("  PASS | %-22s | MEM[%0d]=%0d", lbl, widx*4, $signed(exp));
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-22s | MEM[%0d] exp=%0d got=%0d",
                    lbl, widx*4, $signed(exp), $signed(`MEM(widx)));
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_pc;
        input [31:0]   exp;
        input [30*8:1] lbl;
        begin
            if (dut.pc_current === exp) begin
                $display("  PASS | %-22s | PC=0x%08X", lbl, exp);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL | %-22s | PC exp=0x%08X got=0x%08X",
                    lbl, exp, dut.pc_current);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── stimulus ──────────────────────────────────────────────────
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("================================================");
        $display(" MIPS CPU  -  Full Instruction Testbench  v4");
        $display("================================================");

        // Apply reset for 2 posedges, then release
        reset = 1;
        @(posedge clk); #1;   // cycle 1
        @(posedge clk); #1;   // cycle 2
        reset = 0;
        // cycle 3 posedge will be the first free-running cycle

        // ── cycle 3: PC=0x04, R1=10 written ──────────────────────
        @(posedge clk); #1;
        $display("--- [1] ADDI $1,$0,10 ---");
        check_reg(1, 32'd10, "ADDI $1=10");

        // ── cycle 4: PC=0x08, R2=20 written ──────────────────────
        @(posedge clk); #1;
        $display("--- [2] ADDI $2,$0,20 ---");
        check_reg(2, 32'd20, "ADDI $2=20");

        // ── cycle 5: PC=0x0C, R3=-5 written ──────────────────────
        @(posedge clk); #1;
        $display("--- [3] ADDI $3,$0,-5 (sign-ext) ---");
        check_reg(3, 32'hFFFFFFFB, "ADDI $3=-5");

        // ── cycle 6: PC=0x10, R4=30 written ──────────────────────
        @(posedge clk); #1;
        $display("--- [4] ADD $4,$1,$2 ---");
        check_reg(4, 32'd30, "R-ADD $4=30");

        // ── cycle 7: PC=0x14, R5=10 written ──────────────────────
        @(posedge clk); #1;
        $display("--- [5] SUB $5,$2,$1 ---");
        check_reg(5, 32'd10, "R-SUB $5=10");

        // ── cycle 8: PC=0x18, R6=30 written ──────────────────────
        @(posedge clk); #1;
        $display("--- [6] XOR $6,$1,$2 ---");
        check_reg(6, 32'd30, "R-XOR $6=30");

        // ── cycle 9: PC=0x1C, MEM[0]=30 written (SW $4) ──────────
        @(posedge clk); #1;
        $display("--- [7] SW $4,0($0) ---");
        check_mem(0, 32'd30, "SW MEM[0]=30");

        // ── cycle 10: PC=0x20, MEM[4]=10 written (SW $5) ─────────
        @(posedge clk); #1;
        $display("--- [8] SW $5,4($0) ---");
        check_mem(1, 32'd10, "SW MEM[4]=10");

        // ── cycle 11: PC=0x24, R7=30 written (LW) ────────────────
        @(posedge clk); #1;
        $display("--- [9] LW $7,0($0) ---");
        check_reg(7, 32'd30, "LW $7=30");

        // ── cycle 12: PC=0x28, R8=10 written (LW) ────────────────
        @(posedge clk); #1;
        $display("--- [10] LW $8,4($0) ---");
        check_reg(8, 32'd10, "LW $8=10");

        // ── cycle 13: PC=0x2C  BEQ not-taken resolved ────────────
        @(posedge clk); #1;
        $display("--- [11] BEQ $1,$3 NOT TAKEN ---");
        check_pc(32'h0000002C, "BEQ not-taken PC=0x2C");

        // ── cycle 14: PC=0x30, R1=11 written (ADDI $1,$1,1) ──────
        @(posedge clk); #1;
        $display("--- [12] ADDI $1,$1,1  (BEQ not-taken proof) ---");
        check_reg(1, 32'd11, "After BEQ NT: $1=11");

        // ── cycle 15: PC=0x38  BEQ taken resolved ────────────────
        // instr13 (ADDI $2,$0,99) was skipped → $2 must still be 20
        @(posedge clk); #1;
        $display("--- [13] BEQ $4,$7 TAKEN ---");
        check_pc(32'h00000038, "BEQ taken PC=0x38");
        $display("--- [14] Instr13 SKIP proof ---");
        check_reg(2, 32'd20, "Skipped: $2 stays 20");

        // ── cycle 16: PC=0x00  JUMP resolved ─────────────────────
        @(posedge clk); #1;
        $display("--- [15] JUMP to 0 ---");
        check_pc(32'h00000000, "JUMP PC=0x00");

        // ── summary ───────────────────────────────────────────────
        $display("\n================================================");
        $display(" TOTAL: %0d PASSED   %0d FAILED   (of %0d)",
            pass_count, fail_count, pass_count + fail_count);
        if (fail_count == 0)
            $display(" *** ALL 15 TESTS PASSED - CPU IS CORRECT! ***");
        else
            $display(" *** FAILURES ABOVE ***");
        $display("================================================");

        $finish;
    end

endmodule