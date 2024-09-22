///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	BypassBuff
///////////////////////////////////////////////////////////////////////////////////////////////////

module BypassBuff
	import pkg_tpu::*;
#(
	parameter int BUFF_SIZE		= 8
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Force Stalling
	input	dst_t				I_WB_Index,				//Write-back Index
	input	data_t				I_WB_Data,				//Write-back Data
	input	reg_t				I_Src1,					//Source Data
	input	reg_t				I_Src2,					//Source Data
	input	reg_t				I_Src3,					//Source Data
	output	reg_t				O_Src1,					//Source Data
	output	reg_t				O_Src2,					//Source Data
	output	reg_t				O_Src3,					//Source Data
	output						O_Full					//Full in Buffer
);


	localparam int	WIDTH_NUM	= $clog2(BUFF_SIZE);

	logic						En;

	logic	[BUFF_SIZE-1:0]		Valid;

	logic	[BUFF_SIZE-1:0]		is_Matched_Src1;
	logic	[BUFF_SIZE-1:0]		is_Matched_Src2;
	logic	[BUFF_SIZE-1:0]		is_Matched_Src3;

	logic	[WIDTH_NUM-1:0]		NoSrc1;
	logic	[WIDTH_NUM-1:0]		NoSrc2;
	logic	[WIDTH_NUM-1:0]		NoSrc3;
	logic	[WIDTH_NUM-1:0]		Sel_NoSrc;

	logic	[WIDTH_NUM-1:0]		Len;

	logic						Hit;
	logic						Hit_Src1;
	logic						Hit_Src2;
	logic						Hit_Src3;

	logic						Update;
	logic						Update_Src1;
	logic						Update_Src2;
	logic						Update_Src3;

	logic						Store;

	logic						Clr;

	logic						Last_Src1;
	logic						Last_Src2;
	logic						Last_Src3;

	logic	[WIDTH_NUM-1:0]		Wr_Ptr;
	logic	[WIDTH_NUM-1:0]		Rd_Ptr;


	logic						Run_Slice_Src1;
	logic						Run_Slice_Src2;
	logic						Run_Slice_Src3;

	index_t						Len_Src1;
	index_t						Len_Src2;
	index_t						Len_Src3;


	logic						valid			[BUFF_SIZE-1:0];
	reg_t						Buff_Index		[BUFF_SIZE-1:0];
	data_t						Buff_Data		[BUFF_SIZE-1:0];


	assign En					= ~I_Stall;

	assign Store				= I_WB_Index.v;

	assign Hit_Src1				= is_Matched_Src1[ Rd_Ptr ] & En;
	assign Hit_Src2				= is_Matched_Src2[ Rd_Ptr ] & En;
	assign Hit_Src3				= is_Matched_Src3[ Rd_Ptr ] & En;
	assign Hit					= Hit_Src1 | Hit_Src2 | Hit_Src3;

	assign Update_Src1			= ( |is_Matched_Src1 ) & En;
	assign Update_Src2			= ( |is_Matched_Src2 ) & En;
	assign Update_Src3			= ( |is_Matched_Src3 ) & En;
	assign Update				= Update_Src1 | Update_Src2 | Update_Src3;


	assign O_Src1				= ( Update_Src1 ) ?	Buff_Data[ NoSrc1 ] :
									( Hit_Src1 ) ?	Buff_Data[ Rd_Ptr ] :
									I_Src1;

	assign O_Src2				= ( Update_Src2 ) ?	Buff_Data[ NoSrc2 ] :
									( Hit_Src2 ) ?	Buff_Data[ Rd_Ptr ] :
													I_Src2;

	assign O_Src3				= ( Update_Src3 ) ?	Buff_Data[ NoSrc3 ] :
									( Hit_Src3 ) ?	Buff_Data[ Rd_Ptr ] :
													I_Src3;


	assign Last_Src1			= Run_Slice_Src1 ^ ( I_Src1.idx == Len_Src1 );
	assign Last_Src2			= Run_Slice_Src2 ^ ( I_Src2.idx == Len_Src2 );
	assign Last_Src3			= Run_Slice_Src3 ^ ( I_Src3.idx == Len_Src3 );

	assign Clr					= Last_Src1 & Last_Src2 & Last_Src3;


	always_comb begin
		for ( int i=0; i<BUFF_SIZE; ++i ) begin
			is_Matched_Src1[ i ]	= Valid[ i ] & Buff_Index[ i ].v & I_Src1.v & ( Buff_Index[ i ].idx == I_Src1.idx );
			is_Matched_Src2[ i ]	= Valid[ i ] & Buff_Index[ i ].v & I_Src2.v & ( Buff_Index[ i ].idx == I_Src2.idx );
			is_Matched_Src3[ i ]	= Valid[ i ] & Buff_Index[ i ].v & I_Src3.v & ( Buff_Index[ i ].idx == I_Src3.idx );
		end
	end


	always_comb begin
		if ( ( NoSrc1 >= NoSrc2 ) & ( NoSrc1 >= NoSrc3 ) ) begin
			assign Sel_NoSrc	= NoSrc1;
		end
		else if ( ( NoSrc2 >= NoSrc1 ) & ( NoSrc2 >= NoSrc3 ) ) begin
			assign Sel_NoSrc	= NoSrc2;
		end
		else if ( ( NoSrc3 >= NoSrc1 ) & ( NoSrc3 >= NoSrc2 ) ) begin
			assign Sel_NoSrc	= NoSrc3;
		end
		else begin
			assign Sel_NoSrc	= '0;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run_Slice_Src1	<= 1'b0;
		end
		else if ( Last_Src1 ) begin
			Run_Slice_Src1	<= 1'b0;
		end
		else if ( I_Src1.v & ( I_Src1.slice_len != 0 ) ) begin
			Run_Slice_Src1	<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run_Slice_Src2	<= 1'b0;
		end
		else if ( Last_Src2 ) begin
			Run_Slice_Src2	<= 1'b0;
		end
		else if ( I_Src2.v & ( I_Src2.slice_len != 0 ) ) begin
			Run_Slice_Src2	<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run_Slice_Src3	<= 1'b0;
		end
		else if ( Last_Src3 ) begin
			Run_Slice_Src3	<= 1'b0;
		end
		else if (  I_Src3.v & ( I_Src3.slice_len != 0 ) ) begin
			Run_Slice_Src3	<= 1'b1;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Len_Src1		<= 0;
		end
		else if ( I_Src1.v & ( I_Src1.slice_len != 0 ) ) begin
			Len_Src1		<= I_Src1.slice_len + I_Src1.idx;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Len_Src2		<= 0;
		end
		else if ( I_Src2.v & ( I_Src2.slice_len != 0 ) ) begin
			Len_Src2		<= I_Src2.slice_len + I_Src2.idx;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Len_Src3		<= 0;
		end
		else if ( I_Src3.v & ( I_Src3.slice_len != 0 ) ) begin
			Len_Src3		<= I_Src3.slice_len + I_Src3.idx;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i>BUFF_SIZE; ++i ) begin
				Valid[ i ]		<= 1'b0;
				Buff_Index[ i ]	<= '0;
				Buff_Data[ i ]	<= '0;
			end
		end
		else if ( Update | Hit | Store ) begin
			if ( Clr & Hit ) begin
				Valid[ Rd_Ptr ]	<= 1'b0;
			end
			else if ( Clr & Update & ( Rd_Ptr <= Sel_NoSrc ) ) begin
				for ( int i=Rd_Ptr; i<Sel_NoSrc; ++i ) begin
					Valid[ i ]	<= 1'b0;
				end
			end
			else if ( Clr & Update ) begin
				for ( int i=Sel_NoSrc; i<BUFF_SIZE; ++i ) begin
					Valid[ i ]	<= 1'b0;
				end

				for ( int i=0; i<Rd_Ptr; ++i ) begin
					Valid[ i ]	<= 1'b0;
				end
			end

			if ( Store ) begin
				Valid[ Wr_Ptr ]			<= 1'b1;
				Buff_Index[ Wr_Ptr ]	<= I_WB_Index;
				Buff_Data[ Wr_Ptr ]		<= I_WB_Data;
			end
		end
	end


	Encoder #(
		.NUM_ENTRY(			BUFF_SIZE				)
	) EncSrc1
	(
		.I_Data(			is_Matched_Src1			),
		.O_Enc(				NoSrc1					)
	);

	Encoder #(
		.NUM_ENTRY(			BUFF_SIZE				)
	) EncSrc2
	(
		.I_Data(			is_Matched_Src2			),
		.O_Enc(				NoSrc2					)
	);

	Encoder #(
		.NUM_ENTRY(			BUFF_SIZE				)
	) EncSrc3
	(
		.I_Data(			is_Matched_Src3			),
		.O_Enc(				NoSrc3					)
	);


	RingBuffCTRL_Re #(
		.NUM_ENTRY(			BUFF_SIZE				)
	) RingBuffCTRL
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Update(			Update					),
		.I_UpdateLen(		Sel_NoSrc				),
		.I_We(				Store					),
		.I_Re(				Hit						),
		.O_WAddr(			Wr_Ptr					),
		.O_RAddr(			Rd_Ptr					),
		.O_Full(			O_Full					),
		.O_Empty(									),
		.O_Num(										)
	);

endmodule