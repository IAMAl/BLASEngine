///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	CommitAgg_Unit
///////////////////////////////////////////////////////////////////////////////////////////////////

module CommitAgg_Unit
	import pkg_top::*;
	import pkg_mpu::*;
#(
	parameter int	NUM_LANES	= 1,
	parameter int	BUFF_SIZE	= 4
)(
	input						clock,
	input						reset,
	input						I_Req,					//Issue Request
	input	issue_no_t  		I_Issue_No,				//Issue Number
	input	v_ready_t   		I_Commit_Req,			//Commit Request from Scalar Unit
	input	v_issue_no_t		I_Commit_No,			//Commit Number	from Scalar Unit
	output						O_Commit_Req,			//Commit Request to Scalar Unit
	output	issue_no_t  		O_Commit_No,			//Commit Number to Scalar Unit
	input						I_Commit_Grant,			//Commit Grant from Scalar Unit
	output						O_Full					//Flag: Buffer Full
);


	localparam int	WIDTH_SIZE	= $clog2(BUFF_SIZE);


	logic						Send_Commit;
	logic	[NUM_LANES-1:0]		is_Matched		[BUFF_SIZE-1:0];
	logic	[BUFF_SIZE-1:0]		is_Commit;

	logic						We;
	logic						Re;
	logic	[WIDTH_SIZE-1:0]	Wr_Ptr;
	logic	[WIDTH_SIZE-1:0]	Rd_Ptr;


	commit_agg_t				CommitAgg		[BUFF_SIZE-1:0];


	assign We					= I_Commit_Req;
	assign Re					= Send_Commit & I_Commit_Grant;

	assign Send_Commit			= CommitAgg[ Rd_Ptr ].v & ( &( ~( CommitAgg[ Rd_Ptr ].commit ^ CommitAgg[ Rd_Ptr ].en_tpu ) ) );

	assign O_Commit_Req			= Send_Commit;
	assign O_Commit_No			= CommitAgg[ Rd_Ptr ].issue_no;


	always_comb begin
		for ( int i=0; i<BUFF_SIZE; ++i ) begin
			is_Commit[ i ]	= |is_Matched[ i ];
		end
	end

	always_comb begin
		for ( int j=0; j<NUM_LANES; ++j ) begin
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
		else if ( Re | I_Req ) begin
			if ( Re ) begin
				CommitAgg[ Rd_Ptr ].v		<= 1'b0;
				CommitAgg[ Rd_Ptr ].en_tpu	<= '0;
                CommitAgg[ Rd_Ptr ].commit	<= '0;
			end

			if ( I_Req ) begin
				CommitAgg[ Wr_Ptr ].v		<= 1'b1;
				CommitAgg[ Wr_Ptr ].en_tpu	<= 1'b1;
				CommitAgg[ Wr_Ptr ].commit	<= '0;
				CommitAgg[ Wr_Ptr ].issue_no<= I_Issue_No;
			end

			if ( |is_Commit ) begin
				for ( int i=0; i<BUFF_SIZE; ++i ) begin
					for ( int j=0; j<NUM_LANES; ++j ) begin
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
		.I_We(				We						),
		.I_Re(				Re						),
		.O_WAddr(			Wr_Ptr					),
		.O_RAddr(			Rd_Ptr					),
		.O_Full(			O_Full					),
		.O_Empty(									),
		.O_Num(										)
	);

endmodule