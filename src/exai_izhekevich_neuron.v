/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_exai_izhekevich_neuron (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All numbers are signed (18-bit) 8.9 fixed point numbers where:
  //  the MSB is the sign bit
  // the next 7 bits are the integer part
  // the last 9 bits are the fractional part
  // 2 = 0b0_00000010_00000000
  // 0.02 = 0b0_00000000_00000010

  // Param A: default is 0.02 (0b0_0000000_000000010)
  parameter signed a = 18'b0_00000000_000000010;
  // Param B: default is 0.02 (0b0_0000000_000000010)
  parameter signed b = 18'b0_00000000_000000010;
  // Param C: default is -65 (0b1_0000000_000000000)
  parameter signed c = 18'b1_01000001_000000000;
  // Param D: default is 8 (0b0_0000000_0000000000)
  parameter signed d = 18'b0_00001000_0000000000;
  localparam size = 18;
  // Peak overshoot (voltage threshold for spike detection) = 30
  localparam signed p =  18'b0_0011110_0000000000;
  // 140 used in the equation: `v[n+1] = v + (0.04 * v[n]^2) + (5 * v[n]) + 140 - u[n] + I`
  localparam signed c14 = 18'b0_10001100_0000000000;
  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;


  // Read in parameters based on behavior selection
  // ui_in[0-2] = behavior selection, where:
  /** 
    | Behavior                    | A   | B    | C   | D   |
    | --------------------------- | --- | ---- | --- | --- |
   0| RS (Regular Spiking)        | .02 | .02  | -65 | 8   |
   1| IB (Intrinsically Bursting) | .02 | .02  | -55 | 4   |
   2| CH (Chattering)             | .02 | .02  | -50 | 2   |
   3| FS (Fast Spiking)           | 0.1 | 0.2  | -65 | 2   |
   4| TC (Thalamo-Cortical)       | .02 | 0.25 | -65 | .05 |
   5| RZ (Resonator)              | 0.1 | 0.25 | -65 | 2   |
   6| LTS (Low Threshold Spiking) | .02 | 0.25 | -65 | 2   |
  */

  // Parameters
  reg signed [size-1:0] v1, u1, i;
  wire signed [size-1:0] v1new, u1new, ureset;
  wire signed [size-1:0] v1xv1, du, v1xb;

  always @ (posedge clk) 
	  begin
		  if (rst_n == 0) //reset
		  begin	
			  v1 <= c;  // Set v1 to c (default is -65)
			  u1 <= d;  // Set u1 to d (default is 8)   
        i <= 0;    
		end
		else if(ena) // If tile enabled
		  begin
        // Compare integer part of v1 to integer part of p (30)
        // Cheap way to check negativity
			  if ((v1 > p)) // If v1 is greater than p
			    begin  // Spike
				    v1 <= c; 		
				    u1 <= ureset;
            i[16:9] <= ui_in[7:0]; // Set i to input
			    end
			  else     // No spike
			    begin
				    v1 <= v1new ;
				    u1 <= u1new ; 
            i[16:9] <= ui_in[7:0]; // Set i to input
		    	end 
		  end 
      uio_out = v1[16:9]; // Output integer part of v1
	end


  // dt = 1/16 or 2>>4
	// v1(n+1) = v1(n) + dt*(4*(v1(n)^2) + 5*v1(n) +1.40 - u1(n) + I)
	// but note that what is actually coded is
	// v1(n+1) = v1(n) + (v1(n)^2) + 5/4*v1(n) +1.40/4 - u1(n)/4 + I/4)/4
	signed_mult #(size)v1sq(v1xv1, v1, v1);
	assign v1new = v1 + ((v1xv1 + v1+(v1>>>2) + (c14>>>2) - (u1>>>2) + (i>>>2))>>>2);
	
	// u1(n+1) = u1 + dt*a*(b*v1(n) - u1(n))
	signed_mult #(size) bb(v1xb, v1, b);
	signed_mult #(size) aa(du, (v1xb-u1), a);
	assign u1new = u1 + (du>>>4); 
	assign ureset = u1 + d ;

endmodule


// Multiplier module for signed 8.9 fixed point numbers
// Input: a, b as signed 18-bit numbers where:
//  the MSB is the sign bit,
//  the next 7 bits are the integer part,
//  the last 9 bits are the fractional part

module signed_mult #(parameter size = 18)(out, a, b);
 
	output 		[size-1:0]	out;
	input 	signed	[size-1:0] 	a;
	input 	signed	[size-1:0] 	b;
	
	wire	signed	[size-1:0]	out;
	wire 	signed	[(2*size)-1:0]	mult_out;

	assign mult_out = a * b;   
  assign out = {mult_out[(2*size)-1],mult_out[size+14:32], mult_out[31:16]};
	////////////// sign bit ---------// integer bits /// fractional bits ////
endmodule



