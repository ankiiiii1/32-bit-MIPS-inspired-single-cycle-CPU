`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/24/2026 02:43:36 PM
// Design Name: 
// Module Name: mux
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


module mux(

    input  wire I0,   // Input 0
    input  wire I1,   // Input 1
    input  wire S,    // Select signal
    output wire Y     // Output
);

assign Y = (S == 1'b0) ? I0 : I1;

endmodule
