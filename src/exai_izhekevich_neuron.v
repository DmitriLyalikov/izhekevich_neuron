/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

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
  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = uio_in;
  assign uio_oe  = 0;
  
  wire [3:0] a, b;
  reg signed [17:0] v1, u1;
  wire signed [17:0] u1reset, v1new, u1new, du1;
  wire signed [17:0] v1xv1, v1xb;
  wire signed [17:0] p, c14;
  wire signed [17:0] c, d;
  wire signed [17:0] I;

  assign a = uio_in[3:0];
  assign b = uio_in[7:4];
  assign c = 18'shA_6666;   // 5.4
  assign d = 18'sh0_4CCD;   // 0.2
  assign p = 18'shA_6666;   // 30
  assign c14 = 18'sh1_6666; // 1.4
  // Set the input of ui_in[7:0] to last 8 bits of I, 
  assign I = {ui_in[7:0], 10'hFF};
  // Parameters
  always @ (posedge clk)
  begin 
    if (!rst_n)
    begin
      v1 <= 18'sh3_4CCD; // -0.7v
      u1 <= 18'sh3_CCCD; // -0.2
    end
    else
    if (ena)
    begin
      if ((v1 > p))
      begin
        v1 <= c;
        u1 <= u1reset;
      end
      else
      begin
        v1 <= v1new;
        u1 <= u1new;
      end
    end
  end
  assign uo_out = v1[17:10]; // 2.8 format
  // dt = 1/16 or 2>>4
  // v1(n+1) = v1(n) + dt*(4*(v1(n)^2) + 5*v1(n) +1.40 - u1(n) +I)
  // What is actually implemented is:
  // v1(n+1) = v1(n) + (v1(n)^2) + 5/4*v1(n) +1.40/4 - u1(n)/4 + I/4)/4
  signed_mult v1sq(v1xv1, v1, v1);
  assign v1new = v1 + ((v1xv1 + v1+(v1>>>2) + (c14>>>2) - (u1>>>2) + (I>>>2))>>>2);

  // u1(n+1) = u1 + dt*a*(b*v1(n) - u1(n))
  assign v1xb = v1>>>b;         //mult (v1xb, v1, b);
	assign du1 = (v1xb-u1)>>>a ;  //mult (du1, (v1xb-u1), a);
	assign u1new = u1 + (du1>>>4) ; 
	assign u1reset = u1 + d ;
  
endmodule

//////////////////////////////////////////////////
//// signed mult of 2.16 format 2'comp////////////
//////////////////////////////////////////////////

module signed_mult (out, a, b);

	output 		[17:0]	out;
	input 	signed	[17:0] 	a;
	input 	signed	[17:0] 	b;
	
	wire	signed	[17:0]	out;
  /* verilator lint_off UNUSEDSIGNAL */
	wire 	signed	[35:0]	mult_out;

  // Remove linter warning of unused bits
	assign mult_out = a * b;
	//assign out = mult_out[33:17];
	assign out = {mult_out[35], mult_out[32:16]};
endmodule
