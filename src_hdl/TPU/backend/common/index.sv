module Index
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Stall,						//Force Stalling
	input						I_Req,							//Request from Previous Stage
	input						I_Slice,						//Flag: Index-Slicing
	input	index_t				I_Index,						//Index Value
	input	index_t				I_Length,						//Length for Slicing
	input	id_t				I_ThreadID_Scalar,				//Scalar Thread ID
	input	id_t				I_ThreadID_SIMT,				//SIMT Thread ID
	input	id_t				I_Constant,						//Constant
	input						I_Sign,							//Config: Sign
	output						O_Req,							//Request to Next Stage
	output						O_Slice,						//Flag: Index-Slicing
	output						O_Index							//Index Value
);


	index_t						Index;
	logic						En_Slice;
	logic						End_Count;

	index_sel_t					Sel_a;
	index_sel_t					Sel_b;
	index_sel_t					Sel_c;
	logic						Sel_Const;

	logic						sign;
	index_t						Index_a;
	index_t						Index_b;
	index_t						Index_c;
	index_t						Index_s1;
	index_t						Index_s2;
	index_t						Index_val;

	logic						R_Req;
	logic						R_Sel;
	index_t						R_Index;

	assign En_Slice				= ( I_Req & I_Slice ) | ( R_Sel & ~I_Stall );
	assign End_Count			= CountVal == R_Length;
	assign Index				= ( R_Sel ) ? CountVal + R_Index + 1'b1 : I_Index;

	assign sign					= I_Sign;

	assign Index_a				= ( Sel_a == INDEX_SIMT ) ?		I_ThreadID_SIMT :
									( Sel_a == INDEX_CONST ) ? 	I_Constant :
									( Sel_a == INDEX_ORIG ) ?	Index :
																0;

	assign Index_b				= ( Sel_b == INDEX_SCALAR ) ?	I_ThreadID_Scalar :
									( Sle_b == INDEX_CONST ) ? 	I_Constant :
									( Sel_b == INDEX_ORIG ) ?	Index :
																0;

	assign Index_c				= ( Sel_c == INDEX_SCALAR ) ?	I_ThreadID_Scalar :
									( Sle_c == INDEX_CONST ) ? 	I_Constant :
									( Sel_c == INDEX_ORIG ) ?	Index :
																I_ThreadID_SIMT;

	assign Index_m				= index_a * index_b;
	assign index_s1				= ( I_Constant ) ?				index_m : index_c;
	assign index_s2				= ( I_Constant ) ?				index_c : index_m;
	assign index_val			= ( sign ) ?					index_s1 - index2 : index_s1 + index_s2;

	assign O_Req				= R_Req | R_Sel;
	assign O_Slice				= R_Sel;
	assign O_Index				= R_Index;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else begin
			R_Req				= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Sel				<= 1'b0;
		end
		else if ( End_Count ) begin
			R_Sel				<= 1'b0;
		end
		else if ( I_Req & ~I_Stall & I_Slice ) begin
			R_Sel				<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Index				<= 0;
		end
		else if ( R_Sel & ~I_Stall ) begin
			R_Index			 	<= index_val;
		end
		else if ( I_Req & ~I_Stall ) begin
			R_Index				<= I_Index;
		end
	end

	Counter SliceVal (
		.clock(				clock					),
		.reset(				reset					),
		.I_Clr(				End_Count				),
		.I_En(				En_Slice				),
		.O_Val(				Countval				)
	)
endmodule