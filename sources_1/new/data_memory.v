`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 03:08:43 PM
// Design Name: 
// Module Name: data_memory
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


module data_memory(


    input clk,
    input MemWrite,
    input MemRead,
    input [31:0] Address,      // From ALU Result
    input [31:0] Write_Data,   // From Register File (Read_Data2)
    output reg [31:0] Read_Data
);
    // Create memory: 256 words, each 32 bits wide
    reg [31:0] dmem [0:255];

    // Combinational Read
    always @(*) begin
        if (MemRead)
            Read_Data = dmem[Address[31:2]]; // Word aligned!
        else
            Read_Data = 32'b0;
    end

    // Synchronous Write
    always @(posedge clk) begin
        if (MemWrite) begin
            dmem[Address[31:2]] <= Write_Data; // Word aligned!
        end
    end
endmodule
