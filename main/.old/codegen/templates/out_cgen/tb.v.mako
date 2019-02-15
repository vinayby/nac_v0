`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:46:11 08/21/2015
// Design Name:   mkTop
// Module Name:   /home/dhiman/workspace/ise/connect/tb.v
// Project Name:  connect
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mkTop
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb;

	// Inputs
	reg CLK;
	reg RST_N;

	// Instantiate the Unit Under Test (UUT)
	mkTb tb (
		.CLK(CLK), 
		.RST_N(RST_N)
	);
	always #4 CLK = ~CLK;
	initial begin
		// Initialize Inputs
		CLK = 0;
		RST_N = 0;
		#4 RST_N = 0;
		#16 RST_N = 1;

		// Wait 100 ns for global reset to finish
		//#100;
       		#500000 $finish(); 
		// Add stimulus here

	end
     	initial begin	
		//$dumpfile("dump.vcd");
		//$dumpvars(0);
	end 
endmodule

