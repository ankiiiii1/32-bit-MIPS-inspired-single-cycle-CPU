`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 03:07:42 PM
// Design Name: 
// Module Name: program_counter
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


module program_counter(

    input clk,
    input reset,
    input [31:0] pc_next,
    output reg [31:0] pc_current
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_current <= 32'b0;      // Start at address 0
        else
            pc_current <= pc_next;    // Move to next instruction
    end

endmodule
