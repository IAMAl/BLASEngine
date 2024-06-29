module reorderbuff_v #(
	parameter NUM_ENTRY = 16;
)(
	input						clock,
	input						reset,
	input						I_Store,
	input	issue_no_t			I_Issue_No,
	input						I_Commit_Req,
	output	logic				O_Commit_Req,
	output	issue_no_t			O_Commit_No,
	output	logic				O_Full
);


	localparam WIDTH_ENTRY		= $clog2(NUM_ENTYRY);

	commit_tab_v				Commit_V	[NUM_ENTRY-1:0];

	logic	[NUM_ENTRY-1:0]		Clr_Valid;
	logic	[NUM_ENTRY-1:0]		Set_Commit;

	logic						We;
	logic						Re;
	logic	[WIDTH_ENTRY-1:0]	WNo;
	logic	[WIDTH_ENTRY-1:0]	RNo;
	logic						Empty;
	logic						Full;

	assign O_Commit_Req			= Re;
	assign O_Commit_No			= Commit_V[RNo].Issue_No;
	assign O_Full				= Full;

	assign Re					= Commit_V[RNo].Valid & Commit_V[RNo].Commit;
	assign We					= I_Store & ~Full;

	always_comb: begin
		for ( int i=0; i<NUM_ENTRY; ++i ) begin
			Set_Commit[i]		= Commit_V[i].En_Lane ^ Commit_V[i].Commit;
		end
	end

    always_comb: begin
        for ( int i=0; i<NUM_ENTRY; ++i ) begin
            assign Clr_Valid[i]     = Commit_V[i].Valid & Commit_V[i].Commit;
        end
    end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_V[i]		<= '0;
			end
		end
		else if ( I_Store | I_Commit_Req | ( Set_Commit != 0 ) ) begin
			if ( I_Store ) begin
				Commit_V[i].Valid	<= 1'b1;
				Commit_V[i].Issue_No<= I_Issue_No;
				Commit_V[i].EN_Lane	<= I_En_Lane;
				Commit_V[i].Commit	<= 0;
			end

			if ( I_Commit_Req ) begin
				Commit_V[i].Valid	<= 1'b0;
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_V[i].Commit	<= Set_Commit[i];
			end

			for ( int i=0; i<NUM_ENTRY; ++i ) begin
				Commit_S[i].Valid	<= Commit_S[i].Valid & ~Clr_Valid[i];
				Commit_S[i].Commit	<= Commit_S[i].Commit & ~Clr_Valid[i];
			end
		end
	end


	//// Module: Ring-Buffer Controller
	RingBuffCTRL #(
		.NUM_ENTRY(			NUM_ENTRY					)
	) RingBuffCTRL
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WNo							),
		.O_RAddr(			RNo							),
		.O_Full(			Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

endmodule