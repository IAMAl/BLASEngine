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
	input						I_Valid,
	input	index_t				I_WB_Index,				//Write-back Index
	input	data_t				I_WB_Data,				//Write-back Data
	input	index_t				I_Slice_Len,			//SLice Length
	input						I_Idx_v1,
	input						I_Idx_v2,
	input						I_Idx_v3,
	input	index_t				I_Idx1,					//Index
	input	index_t				I_Idx2,					//Index
	input	index_t				I_Idx3,					//Index
	input	data_t				I_Src1,					//Source Data
	input	data_t				I_Src2,					//Source Data
	input	data_t				I_Src3,					//Source Data
	output	data_t				O_Src1,					//Source Data
	output	data_t				O_Src2,					//Source Data
	output	data_t				O_Src3,					//Source Data
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


	index_t						Buff_Index		[BUFF_SIZE-1:0];
	data_t						Buff_Data		[BUFF_SIZE-1:0];


	assign En					= ~I_Stall;

	assign Store				= I_Valid;

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
									( I_Idx_v1 ) ?	I_Src1 :
													'0;

	assign O_Src2				= ( Update_Src2 ) ?	Buff_Data[ NoSrc2 ] :
									( Hit_Src2 ) ?	Buff_Data[ Rd_Ptr ] :
									( I_Idx_v2 ) ?	I_Src2 :
													'0;

	assign O_Src3				= ( Update_Src3 ) ?	Buff_Data[ NoSrc3 ] :
									( Hit_Src3 ) ?	Buff_Data[ Rd_Ptr ] :
									( I_Idx_v3 ) ?	I_Src3 :
													'0;


	assign Last_Src1			= Run_Slice_Src1 ^ ( I_Idx1 == Len_Src1 );
	assign Last_Src2			= Run_Slice_Src2 ^ ( I_Idx2 == Len_Src2 );
	assign Last_Src3			= Run_Slice_Src3 ^ ( I_Idx3 == Len_Src3 );

	assign Clr					= ~( Run_Slice_Src1 | Run_Slice_Src2 | Run_Slice_Src3 );


	always_comb begin
		for ( int i=0; i<BUFF_SIZE; ++i ) begin
			is_Matched_Src1[ i ]	= Valid[ i ] & I_Idx_v1 & ( Buff_Index[ i ] == I_Idx1 );
			is_Matched_Src2[ i ]	= Valid[ i ] & I_Idx_v2 & ( Buff_Index[ i ] == I_Idx2 );
			is_Matched_Src3[ i ]	= Valid[ i ] & I_Idx_v3 & ( Buff_Index[ i ] == I_Idx3 );
		end
	end


	always_comb begin
		if ( ( NoSrc1 >= NoSrc2 ) & ( NoSrc1 >= NoSrc3 ) ) begin
			Sel_NoSrc	= NoSrc1;
		end
		else if ( ( NoSrc2 >= NoSrc1 ) & ( NoSrc2 >= NoSrc3 ) ) begin
			Sel_NoSrc	= NoSrc2;
		end
		else if ( ( NoSrc3 >= NoSrc1 ) & ( NoSrc3 >= NoSrc2 ) ) begin
			Sel_NoSrc	= NoSrc3;
		end
		else begin
			Sel_NoSrc	= '0;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run_Slice_Src1	<= 1'b0;
		end
		else if ( Last_Src1 ) begin
			Run_Slice_Src1	<= 1'b0;
		end
		else if ( I_Idx_v1 & ( I_Slice_Len != 0 ) ) begin
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
		else if ( I_Idx_v2 & ( I_Slice_Len != 0 ) ) begin
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
		else if ( I_Idx_v3 & ( I_Slice_Len != 0 ) ) begin
			Run_Slice_Src3	<= 1'b1;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Len_Src1		<= 0;
		end
		else if ( I_Idx_v1 & ( I_Slice_Len != 0 ) ) begin
			Len_Src1		<= I_Slice_Len + I_Idx1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Len_Src2		<= 0;
		end
		else if ( I_Idx_v2 & ( I_Slice_Len != 0 ) ) begin
			Len_Src2		<= I_Slice_Len + I_Idx2;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Len_Src3		<= 0;
		end
		else if ( I_Idx_v3 & ( I_Slice_Len != 0 ) ) begin
			Len_Src3		<= I_Slice_Len + I_Idx3;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<BUFF_SIZE; ++i ) begin
				Valid[ i ]		<= 1'b0;
				Buff_Index[ i ]	<= '0;
				Buff_Data[ i ]	<= '0;
			end
		end
		else if ( Update | Hit | Store ) begin
			if ( Clr & Hit ) begin
				Valid[ Rd_Ptr ]	<= 1'b0;
			end
			else if ( Clr & Update ) begin
				for ( int i=0; i<BUFF_SIZE; ++i ) begin
					Valid[ i ]	<= 1'b0;
				end
			end

			if ( Store & ~( Clr & ( Rd_Ptr == Wr_Ptr ) ) ) begin
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