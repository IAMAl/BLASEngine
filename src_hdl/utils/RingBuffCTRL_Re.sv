///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	RingBuffCTRL
///////////////////////////////////////////////////////////////////////////////////////////////////

module RingBuffCTRL_Re
#(
	parameter int NUM_ENTRY			= 16
)(
	input							clock,
	input							reset,
	input							I_Update,			//Force Updating Counter
	input	[$clog2(NUM_ENTRY)-1:0]	I_UpdateLen,		//Updating Amount
	input							I_We,				//Write-Enable
	input							I_Re,				//Read-Enable
	output	[$clog2(NUM_ENTRY)-1:0]	O_WAddr,			//Write Address
	output	[$clog2(NUM_ENTRY)-1:0]	O_RAddr,			//Read Address
	output	logic					O_Full,				//Flag: Full
	output	logic					O_Empty,			//Flag: Empty
    output  [$clog2(NUM_ENTRY):0]	O_Num				//Remained Number of Entries
);

	localparam int WIDTH_BUFF	= $clog2(NUM_ENTRY);


	//// Logic Connect												////
	//	 Pointers
    logic 	[WIDTH_BUFF:0]		W_WPtr;
    logic 	[WIDTH_BUFF:0]		W_RPtr;
    logic 	[WIDTH_BUFF+1:0]	W_CNT;

	logic						Full;
	logic						Empty;


	//// Capture Signal												////
	//	 Count Registers
    logic 	[WIDTH_BUFF:0]		R_WCNT;
    logic 	[WIDTH_BUFF:0]		R_RCNT;


    assign W_WPtr				= R_WCNT;
    assign W_RPtr				= R_RCNT;
    assign W_CNT				= R_WCNT - R_RCNT;


	//// Output 													////
    assign O_WAddr				= W_WPtr[$clog2(NUM_ENTRY)-1:0];
	assign O_RAddr				= W_RPtr[$clog2(NUM_ENTRY)-1:0];
    assign O_Num        	    = ( W_CNT[WIDTH_BUFF+1] ) ?	R_WCNT - R_RCNT + NUM_ENTRY :
															W_CNT[WIDTH_BUFF:0];


	//// Buffer Status												////
	assign Full					= ( O_Num  == (NUM_ENTRY-2));
	assign Empty				= W_CNT[WIDTH_BUFF:0] == '0;
	assign O_Full				= Full;
	assign O_Empty				= Empty;


	//// Pointers													////
	always_ff @( posedge clock ) begin: ff_wcnt
		if ( reset ) begin
			R_WCNT			<= '0;
		end
		else if ( I_We ) begin
			if ( R_WCNT == ( NUM_ENTRY-1 ) ) begin
				R_WCNT  	<= '0;
			end
			else begin
				R_WCNT  	<= R_WCNT + 1'b1;
			end
		end
	end

	always_ff @( posedge clock ) begin: ff_rcnt
		if ( reset ) begin
			R_RCNT			<= '0;
		end
		else if  (( I_Re & ~Empty ) | ( I_Re & I_We & Empty )) begin
			if ( I_Update ) begin
				R_RCNT  	<= I_UpdateLen + 1'b1;
			end
			else if ( R_RCNT == ( NUM_ENTRY-1 ) ) begin
				R_RCNT  	<= '0;
			end
			else begin
				R_RCNT  	<= R_RCNT + 1'b1;
			end
		end
	end

endmodule