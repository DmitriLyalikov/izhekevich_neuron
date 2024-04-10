`default_nettype none

//////////////////////////////////////////////////
//// signed mult of 2.16 format 2'comp////////////
//////////////////////////////////////////////////

module signed_mult #(parameter size = 18)(out, a, b);
 
	output 		[size-1:0]	out;
	input 	signed	[size-1:0] 	a;
	input 	signed	[size-1:0] 	b;
	
	wire	signed	[size-1:0]	out;
	wire 	signed	[(2*size)-1:0]	mult_out;

	assign mult_out = a * b;      
	//assign out = mult_out[33:17];
	assign out = {mult_out[(2*size)-1],mult_out[size+14:32], mult_out[31:16]};
	////////////// sign bit ---------// integer bits /// fractional bits ////
endmodule