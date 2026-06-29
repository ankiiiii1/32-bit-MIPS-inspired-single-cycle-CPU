`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 03:08:21 PM
// Design Name: 
// Module Name: instruction_memory
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


module instruction_memory(
    input [31:0] Address,      // From PC
    output [31:0] Instruction
);
    // Create memory: say, 64 words, each 32 bits wide
    reg [31:0] imem [0:63];

    // Load your machine code into the memory
    initial begin
        // "machine_code.hex" is a text file with your compiled instructions or can add just the a  big binary array memory"imem" directly
        $readmemh("prog4_fib.hex", imem); 
    end

    // Combinational Read using word-aligned address
    assign Instruction = imem[Address[31:2]];
endmodule
