///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	CommitAgg
///////////////////////////////////////////////////////////////////////////////////////////////////

module CommitAgg
	import pkg_top::*;
	import pkg_mpu::*;
#(
	parameter int	NUM_TPU		= 1,
	parameter int	BUFF_SIZE	= 4
)(
	input						clock,
	input						reset,
	input	[NUM_TPU-1:0]		I_En_TPU,				//Enable to Execute on TPU
	input						I_Req,					//Issue Request
	input	mpu_issue_no_t		I_Issue_No,				//Issue Number
	input	tpu_row_clm_t		I_Commit_Req,			//Commit Request
	input	mpu_issue_no_t		I_Commit_No,			//Commit Number
	output						O_Commit_Req,			//Commit Request to MPU
	output	mpu_issue_no_t		O_Commit_No,			//Commit Number to MPU
	output						O_Full					//Flag: Buffer Full
);


	localparam int	WIDTH_SIZE	= $clog2(BUFF_SIZE);


	logic						Send_Commit;
	logic	[NUM_TPU-1:0]		is_Matched		[BUFF_SIZE-1:0];
	logic	[BUFF_SIZE-1:0]		is_Commit;

	logic	[WIDTH_SIZE-1:0]	Wr_Ptr;
	logic	[WIDTH_SIZE-1:0]	Rd_Ptr;


	commit_agg_t				CommitAgg		[BUFF_SIZE-1:0];


	assign Send_Commit			= CommitAgg[ Rd_Ptr ].v & ( &( ~( CommitAgg[ Rd_Ptr ].commit ^ CommitAgg[ Rd_Ptr ].en_tpu ) ) );

	assign O_Commit_Req			= Send_Commit;
	assign O_Commit_No			= CommitAgg[ Rd_Ptr ].issue_no;


	always_comb begin
		for ( int i=0; i<BUFF_SIZE; ++i ) begin
			is_Commit[ i ]	= |is_Matched[ i ];
		end
	end

	always_comb begin
		for ( int j=0; j<NUM_TPU; ++j ) begin
			for ( int i=0; i<BUFF_SIZE; ++i ) begin
				is_Matched[ i ][ j ]	= CommitAgg[ i ].v & CommitAgg[ i ].en_tpu[ j ] & I_Commit_Req[ j ] & ( I_Commit_No[ j ] == CommitAgg[ i ].issue_no );
			end
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<BUFF_SIZE; ++i ) begin
				CommitAgg[ i ]	<= '0;
			end
		end
		else if ( Send_Commit | I_Req ) begin
			if ( Send_Commit ) begin
				CommitAgg[ Wr_Ptr ].v		<= 1'b0;
				CommitAgg[ Wr_Ptr ].en_tpu	<= '0;
			end

			if ( I_Req ) begin
				CommitAgg[ Wr_Ptr ].v		<= 1'b1;
				CommitAgg[ Wr_Ptr ].en_tpu	<= I_En_TPU;
				CommitAgg[ Wr_Ptr ].commit	<= '0;
				CommitAgg[ Wr_Ptr ].issue_no<= I_Issue_No;
			end

			if ( |is_Commit ) begin
				for ( int i=0; i<BUFF_SIZE; ++i ) begin
					for ( int j=0; j<NUM_TPU; ++j ) begin
						CommitAgg[ i ].commit[ j ]	<= CommitAgg[ i ].commit[ j ] | is_Matched[ i ][ j ];
					end
				end
			end
		end
	end


	RingBuffCTRL #(
		.NUM_ENTRY(			BUFF_SIZE				)
	) RingBuffCTRL
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				I_Commit_Req			),
		.I_Re(				Send_Commit				),
		.O_WAddr(			Wr_Ptr					),
		.O_RAddr(			Rd_Ptr					),
		.O_Full(			O_Full					),
		.O_Empty(									),
		.O_Num(										)
	);

endmodule