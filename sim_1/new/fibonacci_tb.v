`timescale 1ns / 1ps
// ================================================================
//  prog4_fib_tb.v  - Full-system program test
//  Program: PROGRAM 4: Fibonacci first 10 to memory
//
//  This program ends in a jump-to-self HALT loop, so the testbench
//  simply runs long enough for it to finish, then checks the final
//  register / memory state. No cycle-exact timing needed.
//
//  IMPORTANT: set instruction_memory to load "prog4_fib.hex"
//             (change the $readmemh filename, or rename the hex to
//              machine_code.hex)
// ================================================================
module prog4_fib_tb;
    reg clk, reset;
    cpu_top dut(.clk(clk), .reset(reset));
    initial clk = 0;
    always #5 clk = ~clk;

    `define REG(n) dut.u_regfile.registers[n]
    `define MEM(n) dut.u_dmem.dmem[n]

    integer pass_count = 0;
    integer fail_count = 0;

    task chk_reg; input [4:0] r; input [31:0] e; input [40*8:1] l; begin
        if (`REG(r) === e) begin
            $display("  PASS | %-22s | $%0d = %0d", l, r, $signed(e));
            pass_count = pass_count+1;
        end else begin
            $display("  FAIL | %-22s | $%0d exp=%0d got=%0d", l, r, $signed(e), $signed(`REG(r)));
            fail_count = fail_count+1;
        end end
    endtask

    task chk_mem; input [7:0] w; input [31:0] e; input [40*8:1] l; begin
        if (`MEM(w) === e) begin
            $display("  PASS | %-22s | MEM[%0d] = %0d", l, w*4, $signed(e));
            pass_count = pass_count+1;
        end else begin
            $display("  FAIL | %-22s | MEM[%0d] exp=%0d got=%0d", l, w*4, $signed(e), $signed(`MEM(w)));
            fail_count = fail_count+1;
        end end
    endtask

    initial begin
        $display("================================================");
        $display(" PROGRAM 4: Fibonacci first 10 to memory");
        $display("================================================");
        reset = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;

        // run the program to completion
        #1200;

        $display("--- Final state checks ---");
        chk_mem(0, 32'd0, "fib[0]=0");
        chk_mem(1, 32'd1, "fib[1]=1");
        chk_mem(2, 32'd1, "fib[2]=1");
        chk_mem(3, 32'd2, "fib[3]=2");
        chk_mem(4, 32'd3, "fib[4]=3");
        chk_mem(5, 32'd5, "fib[5]=5");
        chk_mem(6, 32'd8, "fib[6]=8");
        chk_mem(7, 32'd13, "fib[7]=13");
        chk_mem(8, 32'd21, "fib[8]=21");
        chk_mem(9, 32'd34, "fib[9]=34");
        $display("\n================================================");
        $display(" TOTAL: %0d PASSED  %0d FAILED  (of %0d)",
            pass_count, fail_count, pass_count+fail_count);
        if (fail_count==0)
            $display(" *** PROGRAM RAN CORRECTLY ***");
        else
            $display(" *** PROGRAM FAILED ***");
        $display("================================================");
        $finish;
    end
endmodule