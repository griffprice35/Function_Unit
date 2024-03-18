////////////////////////////////////////////////////////////////////////////////////////////////////
// Filename: function_unit.v
// Author: Griffin Price
// Created: 15 March 2024
// Version: 1.1 (Last Edited: 18 March 2024)
// Description: The function unit takes the operands OpA, OpB from the  
// ROM in the top level entity, and the inputs SW[9:6] from the DE10-Lite board 
// to select the operation.  The outputs are the 8-bit result and 4 status bits, 
// which can be displayed on LEDs[7:0] on the DE10-Lite board.
////////////////////////////////////////////////////////////////////////////////////////////////////

//Do not change the port declarations
module function_unit (result, V, C, N, Z, OpA, OpB, FS);
  input [3:0] FS;
  input [7:0] OpA, OpB;
  output [7:0] result;
  output V, C, N, Z;
  
  wire [7:0] arithResult, logicResult, shiftResult;
  wire [1:0] blockSelect;
  wire vClear, cClear, nClear, zClear;
  wire Vout, Cout, Nout, Zout;
  
  assign blockSelect = FS[3:2];

//Operation Instantiations
arith_circuit r1(arithResult, Cout, Vout, OpA, OpB, FS);
logic_circuit r2(logicResult, OpA, OpB, FS);
shift_circuit r3(shiftResult, OpA, OpB, FS);

//Function Unit 4x1 Mux
assign result = (blockSelect == 2'b0x) ? arithResult : 
					 (blockSelect == 2'b10) ? logicResult :
					 (blockSelect == 2'b11) ? shiftResult : 8'bxxxxxxxx;
					 
//SOP Expressions to Check Status Bits
assign vClear = (~FS[3] & ~FS[1]) | (~FS[3] & ~FS[2] & ~FS[0]);
assign cClear = (~FS[3] & ~FS[1]) | (~FS[3] & ~FS[2] & ~FS[0]);
assign nClear = (~FS[2] & ~FS[3]) | (~FS[1]  & ~FS[0]) | (FS[1] & FS[0]);
assign zClear = (~FS[2] & ~FS[3]) | (~FS[1]  & ~FS[0]) | (FS[1] & FS[0]);

//Logic to Calculate Status Bit Output
nor g3(Zout, result[7], result[6], result[5], result[4], result[3], result[2], result[1], result[0]);
and g5(Nout, result[7], 1'b1);

//Checking and Outputting Status Bits
and g1(V, Vout, vClear);
and g2(C, Cout, cClear);
and g4(Z, Zout, zClear);
and g6(N, Nout, nClear);


endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////

//BLOCK 1 (Arithmetic Block)
module arith_circuit (result, Cout, Vout, OpA, OpB, opselect);
	input [3:0] opselect;
	input [7:0] OpA, OpB;
	output [7:0] result;
	output Cout, Vout;
	wire Cin;
	wire [7:0] ma, mb;
	wire [2:0] select;
	
//Operation Select Instantiation
op_select OS(select[2:0], Cin, opselect[3:0]);

//Multiplexer A and B Instantiation
//Each mux takes in two select bits, one being unique and one being a shared bit
mux_4x1 MUXA(ma, select[2:1], OpA[7:0], ~OpA[7:0], 8'b00000000, OpA[7:0]);
mux_4x1 MUXB(mb, select[1:0], OpB[7:0], ~OpB[7:0], 8'b00000000, OpB[7:0]);

ripple_adder RA(result, Cout, Vout, ma, mb, Cin);

endmodule


//Full Adder Declaration
module full_adder (f, Cout, a, b, Cin);
	input a, b, Cin;
	output f, Cout;
	
	assign f = ~a&~b&Cin | ~a&b&~Cin | a&~b&~Cin | a&b&Cin;
	assign Cout = a&b | a&Cin | b&Cin;
	
endmodule


//Ripple Adder Declaration
module ripple_adder (f, Cout, Vout, a, b, Cin);
	input [7:0] a, b;
	input Cin;
	output [7:0] f;
	output Cout, Vout;
	wire c1, c2, c3, c4, c5, c6, c7;
	
	full_adder fa1(f[0], c1, a[0], b[0], Cin);
	full_adder fa2(f[1], c2, a[1], b[1], c1);
	full_adder fa3(f[2], c3, a[2], b[2], c2);
	full_adder fa4(f[3], c4, a[3], b[3], c3);
	full_adder fa5(f[4], c5, a[4], b[4], c4);
	full_adder fa6(f[5], c6, a[5], b[5], c5);
	full_adder fa7(f[6], c7, a[6], b[6], c6);
	full_adder fa8(f[7], Cout, a[7], b[7], c7);
	
	xor x1(Vout, Cout, c7);

endmodule



//4x1 Mux Declaration
module mux_4x1 (f, select, a, b, c, d);
	input [1:0] select;
	input [7:0] a, b, c, d;
	output [7:0] f;
	
	assign f = (select == 2'b00) ? a : 
				  (select == 2'b01) ? b :
              (select == 2'b10) ? c :
              (select == 2'b11) ? d : 8'bxxxxxxxx;

endmodule


//Operation Select
module op_select(select, Cout, in);
	input [3:0] in;
	output [2:0] select;
	output Cout;
	
	//8x1 Mux
	assign select = (in == 3'b000) ? 3'b000 : 
						 (in == 3'b001) ? 3'b001 :
						 (in == 3'b010) ? 3'b110 :
						 (in == 3'b011) ? 3'b110 :
						 (in == 3'b100) ? 3'b101 :
						 (in == 3'b101) ? 3'b010 : 3'bxxx;
	
	//8x1 Mux
	assign Cout = (in == 3'b000) ? 1'b0 : 
					  (in == 3'b001) ? 1'b1 :
					  (in == 3'b010) ? 1'b0 :
					  (in == 3'b011) ? 1'b1 :
					  (in == 3'b100) ? 1'b1 :
					  (in == 3'b101) ? 1'b1 : 1'bx;
						 
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////

//BLOCK 2 (Logic Block)

module logic_circuit (result, OpA, OpB, opselect);
input [3:0] opselect;
input [7:0] OpA, OpB;
output [7:0] result;

wire [7:0] a, b, c;

//Operation Instantiations
bitwise_and a1(a, OpA, OpB);
notOp notA(b, OpA);
notOp notB(c, OpB);

//Defining New Operation Codes
wire [3:0] newOpSelect = ~opselect;

//Logical Block 8x1 Mux
assign result = (newOpSelect == 3'b111) ? a : 
					 (newOpSelect == 3'b110) ? b :
					 (newOpSelect == 3'b101) ? c : 8'bxxxxxxxx;

endmodule


//Bitwise AND Circuit
module bitwise_and (f, a, b);
	input [7:0] a, b;
	output [7:0] f;
	
	and a1(f[0], a[0], b[0]);
	and a2(f[1], a[1], b[1]);
	and a3(f[2], a[2], b[2]);
	and a4(f[3], a[3], b[3]);
	and a5(f[4], a[4], b[4]);
	and a6(f[5], a[5], b[5]);
	and a7(f[6], a[6], b[6]);
	and a8(f[7], a[7], b[7]);

endmodule


//Not Circuit
module notOp (f, a);
	input [7:0] a;
	output [7:0] f;
	
	not n1(f[0], a[0]);
	not n2(f[1], a[1]);
	not n3(f[2], a[2]);
	not n4(f[3], a[3]);
	not n5(f[4], a[4]);
	not n6(f[5], a[5]);
	not n7(f[6], a[6]);
	not n8(f[7], a[7]);

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////

//BLOCK 3 (Shift Block)

module shift_circuit (result, OpA, OpB, opselect);
input [3:0] opselect;
input [7:0] OpA, OpB;
output [7:0] result;

wire [7:0] a, b, c, d;

//Operation Instantiations
modOp mod4(a, OpB);
left_shift lslB(b, OpB);
right_shift lsrB(c, OpB);
divOp div8(d, OpB);

//Defining New Operation Codes
wire [3:0] newOpSelect = ~opselect;

//Shift Block 4x1 Mux
assign result = (newOpSelect == 2'b11) ? a : 
					 (newOpSelect == 2'b10) ? b :
					 (newOpSelect == 2'b01) ? c : 
					 (newOpSelect == 2'b00) ? d : 8'bxxxxxxxx;

endmodule


module left_shift (f, a);
	input [7:0] a;
	output [7:0] f;
	
	assign f[0] = 1'b0;
	assign f[1] = a[0];
	assign f[2] = a[1];
	assign f[3] = a[2];
	assign f[4] = a[3];
	assign f[5] = a[4];
	assign f[6] = a[5];
	assign f[7] = a[6];
	
endmodule


module right_shift (f, a);
	input [7:0] a;
	output [7:0] f;
	
	assign f[7] = 1'b0;
	assign f[6] = a[7];
	assign f[5] = a[6];
	assign f[4] = a[5];
	assign f[3] = a[4];
	assign f[2] = a[3];
	assign f[1] = a[2];
	assign f[0] = a[1];
	
endmodule


module modOp (f, a);
	input [7:0] a;
	output [7:0] f;
	
	assign f[0] = a[0];
	assign f[1] = a[1];
	assign f[2] = 1'b0;
	assign f[3] = 1'b0;
	assign f[4] = 1'b0;
	assign f[5] = 1'b0;
	assign f[6] = 1'b0;
	assign f[7] = 1'b0;
	
endmodule


module divOp (f, a);
	input [7:0] a;
	output [7:0] f;
	
	assign f[0] = a[3];
	assign f[1] = a[4];
	assign f[2] = a[5];
	assign f[3] = a[6];
	assign f[4] = a[7];
	assign f[5] = a[7];
	assign f[6] = a[7];
	assign f[7] = a[7];

endmodule
