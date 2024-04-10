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


  parameter a = 'sh0_1999;
  parameter b = 20'sh0_3333;
  parameter c = 'shF_599A;
  parameter d = 'sh0_051E;
  localparam size = 20;
  localparam signed p =  'sh0_4CCC ; //peak overshoot
  localparam signed c14 = 'sh1_6666; // constants
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
  reg signed [size-1:0] v1, u1;
  wire signed [size-1:0] v1new, u1new, ureset;
  wire signed [size-1:0] v1xv1, du, v1xb;

  always @ (posedge clk) 
	  begin
		  if (rst == 0) //reset
		  begin	
			  v1 <= c;     
			  u1 <= d;         
			  spike <= 1'b0;
		end
		else if(ena) 
		  begin
			  if ((v1 > p)) 
			    begin 
				    v1 <= c ; 		
				    u1 <= ureset ;
				    spike <= 1'b1;
			    end
			  else
			    begin
				    v1 <= v1new ;
				    u1 <= u1new ; 
			      spike <= 1'b0; 
		    	end 
		  end 
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




