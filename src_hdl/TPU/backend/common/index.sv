module Index
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_Stall,						//Force Stalling
	input						I_Req,							//Request from Hazard-Check Stage
	input						I_Slice,						//Flag: Index-Slicing
	input	[5:0]				I_Sel,							//Select Sources
	input	index_s_t			I_Index,						//Index Value
	input	index_t				I_Window,						//Window for Slicing
	input	index_t				I_Length,						//Length for Slicing
	input	id_t				I_LaneID,						//Lane ID
	input	id_t				I_ThreadID_SIMT,				//SIMT Thread ID
	input	id_t				I_Constant,						//Constant
	input						I_Sign,							//Config: Sign
	output						O_Req,							//Request to Register-Read Stage
	output						O_Slice,						//Flag: Index-Slicing
	output	index_t				O_Index							//Index Value
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

	logic						Next;
	index_t						OffsetVal;

	logic						R_Req;
	logic						R_Sel;
	index_t						R_Index;
	index_t						R_Base_Index;
	index_t						R_Length;
	index_t						R_Window;


	assign Next					= R_Index == R_Window;

	assign Sel_a				= I_Sel[1:0];
	assign Sel_b				= I_Sel[3:2];
	assign Sel_c				= I_Sel[5:4];

	assign En_Slice				= ( I_Req & I_Slice ) | ( R_Sel & ~I_Stall );
	assign End_Count			= CountVal == R_Length;
	assign Index				= ( R_Sel ) ?	R_Index + OffsetVal + 1'b1 :
												I_Index[WIDTH_INDEX-1:0];

	assign sign					= I_Sign;

	assign Index_a				= ( Sel_a == INDEX_SIMT ) ?		I_ThreadID_SIMT :
									( Sel_a == INDEX_CONST ) ? 	I_Constant :
									( Sel_a == INDEX_ORIG ) ?	Index :
																0;

	assign Index_b				= ( Sel_b == INDEX_LANE ) ?		I_LaneID :
									( Sle_b == INDEX_CONST ) ? 	I_Constant :
									( Sel_b == INDEX_ORIG ) ?	Index :
																0;

	assign Index_c				= ( Sel_c == INDEX_LANE ) ?		I_LaneID :
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
			R_Req				<= I_Req;
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

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Base_Index		<= 0;
		end
		else if ( I_Req & ~I_Stall ) begin
			R_Base_Index		<= I_Index;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length			<= 0;
		end
		else if ( I_Req & ~I_Stall ) begin
			R_Length			<= I_Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Window			<= 0;
		end
		else if ( I_Req & ~I_Stall & ( I_Window != 0 ) ) begin
			R_Window			<= I_Window;
		end
	end


	Counter WindowCount (
		.clock(				clock					),
		.reset(				reset					),
		.I_Clr(				En_Slice & Next			),
		.I_En(				En_Slice				),
		.O_Val(				OffsetVal				)
	);

	Counter SliceVal (
		.clock(				clock					),
		.reset(				reset					),
		.I_Clr(				End_Count				),
		.I_En(				En_Slice				),
		.O_Val(				Countval				)
	);

endmodule