`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 03:08:02 PM
// Design Name: 
// Module Name: register_bank
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


module register_bank(


    input clk,
    input RegWrite,                 // Control signal to enable writing
    input [4:0] Read_Reg1,          // 5-bit address for rs
    input [4:0] Read_Reg2,          // 5-bit address for rt
    input [4:0] Write_Reg,          // 5-bit address for rd (or rt)
    input [31:0] Write_Data,        // 32-bit data to write
    output [31:0] Read_Data1,
    output [31:0] Read_Data2
);
    // Create an array of 32 registers, each 32 bits wide
    reg [31:0] registers [31:0];
    
    integer i;
    initial begin
        // Initialize all registers to 0 at start
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    // Combinational Read (Asynchronous)
    assign Read_Data1 = registers[Read_Reg1];
    assign Read_Data2 = registers[Read_Reg2];

    // Synchronous Write
    always @(posedge clk) begin
        // Only write if RegWrite is high AND we aren't trying to write to register 0
        if (RegWrite && (Write_Reg != 5'b00000)) begin
            registers[Write_Reg] <= Write_Data;
        end
    end
endmodule