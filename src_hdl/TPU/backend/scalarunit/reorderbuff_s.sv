///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	ReorderBuff_S
///////////////////////////////////////////////////////////////////////////////////////////////////

module ReorderBuff_S #(
	parameter NUM_ENTRY = 16;
)(
	input						clock,
	input						reset,
	input						I_Store,				//Store Issue No
	input	issue_no_t			I_Issue_No,				//Storing Issue Number
	input						I_Commit_Req_LdSt1,		//Commit Request from LdSt Unit-1
	input						I_Commit_Req_LdSt2,		//Commit Request from LdSt Unit-2
	input						I_Commit_Req_Math,		//Commit Request from Math Unit
    input   issue_no_t          I_Commit_No_LdSt1,		//Commit No from LdSt Unit-1
    input   issue_no_t          I_Commit_No_LdSt2,		//Commit No from LdSt Unit-2
    input   issue_no_t          I_Commit_No_Math,		//Commit No from Math Unit
	input						I_Commit_Grant,			//Commit Grant
	output	logic				O_Commit_Req,			//Commit Request to Hazard Unit
	output	issue_no_t			O_Commit_No,			//Commit Number
	output						O_Commited_LdSt1,		//Commit Grant to LdSt Unit-1
	output						O_Commited_LdSt2,		//Commit Grant to LdSt Unit-2
	output						O_Commited_Math,		//Commit Grant to Math Unit
	output	logic				O_Full,					//State in Full
	output	logic				O_Empty					//State in Empty
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTYRY);

	commit_tab_s				Commit_S	[NUM_ENTRY-1:0];

	logic	[NUM_ENTRY-1:0]		Clr_Valid;
	logic	[NUM_ENTRY-1:0]		Set_Commit;

	logic;						En_Commit

	logic						We;
	logic						Re;
	logic	[WIDTH_ENTRY-1:0]	WNo;
	logic	[WIDTH_ENTRY-1:0]	RNo;
	logic						Empty;
	logic						Full;

	logic						R_Commit_Req_LdSt1;
	logic						R_Commit_Req_LdSt2;
	logic						R_Commit_Req_Math;


	// Send Commit Request
	assign O_Commit_Req			= Re;
	assign O_Commit_No			= Commit_S[RNo].Issue_No;

	// State of Buffer
	assign O_Full				= Full;
	assign O_Empty				= Empty;

	// Buffer Handling
	assign En_Commit			= Commit_S[RNo].Valid & Commit_S[RNo].Commit;
	assign Re					= En_Commit & I_Commit_Grant;
	assign We					= I_Store & ~Full;


	always_comb: begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			assign Set_Commit[ i ]	= Commit_S[ i ].Valid & (
										( Commit_S[ i ].Issue_No == I_Commit_No_LdSt1 ) |
										( Commit_S[ i ].Issue_No == I_Commit_No_LdSt2 ) |
										( Commit_S[ i ].Issue_No == I_Commit_No_Math )
									);
		end
	end

    always_comb: begin
        for ( int i=0; i<NUM_ENTRY; ++i ) begin
            assign Clr_Valid[ i ]     = Commit_S[ i ].Valid & Commit_S[ i ].Commit;
        end
    end


	always_ff @(b posedge clock ) begin
		if ( reset ) begin
			R_Commit_Req_LdSt1	<= 1'b0;
			R_Commit_No_LdSt1	<= 0;
		end
		else if ( O_Commited_LdSt1 ) begin
			R_Commit_Req_LdSt1	<= 1'b0;
			R_Commit_No_LdSt1	<= 0;
		end
		else if ( I_Commit_Req_LdSt1 ) begin
			R_Commit_Req_LdSt1	<= 1'b1;
			R_Commit_No_LdSt1	<= I_Commit_No_LdSt1;
		end
	end

	always_ff @(b posedge clock ) begin
		if ( reset ) begin
			R_Commit_Req_LdSt2	<= 1'b0;
			R_Commit_No_LdSt2	<= 0;
		end
		else if ( O_Commited_LdSt2 ) begin
			R_Commit_Req_LdSt2	<= 1'b0;
			R_Commit_No_LdSt2	<= 0;
		end
		else if ( I_Commit_Req_LdSt2 ) begin
			R_Commit_Req_LdSt2	<= 1'b1;
			R_Commit_No_LdSt2	<= I_Commit_No_LdSt2;
		end
	end

	always_ff @(b posedge clock ) begin
		if ( reset ) begin
			R_Commit_Req_Math	<= 1'b0;
			R_Commit_No_Math	<= 0;
		end
		else if ( O_Commited_Math ) begin
			R_Commit_Req_Math	<= 1'b0;
			R_Commit_No_Math	<= 0;
		end
		else if ( I_Commit_Req_Math ) begin
			R_Commit_Req_Math	<= 1'b1;
			R_Commit_No_Math	<= I_Commit_No_Math;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_S[i]		<= '0;
			end
		end
		else if ( I_Store | ( Set_Commit != 0) | ( Clr_Valid != 0 ) ) begin
			if ( I_Store ) begin
				Commit_S[ WNo ].Valid	<= 1'b1;
				Commit_S[ WNo ].Issue_No<= I_Issue_No;
				Commit_S[ WNo ].Commit	<= 1'b0;
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_S[ i ].Commit	<= Commit_V[ i ].Commi | Set_Commit[ i ];
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_S[ i ].Valid		<= Commit_S[ i ].Valid &  ~Clr_Valid[ i ];
				Commit_S[ i ].Commit	<= Commit_S[ i ].Commit & ~Clr_Valid[ i ];
			end
		end
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY				)
	) RingBuffCTRL
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.O_WAddr(			WNo						),
		.O_RAddr(			RNo						),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);

endmodule