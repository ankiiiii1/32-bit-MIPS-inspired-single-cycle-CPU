module adder_32bit (
    input  [31:0] A,     // First 32-bit input
    input  [31:0] B,     // Second 32-bit input
    output [31:0] SUM,   // 32-bit sum output
    output        overflow   // Over_flow
);

assign {overflow, SUM} = A + B;

endmodule