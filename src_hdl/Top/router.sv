///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Router
///////////////////////////////////////////////////////////////////////////////////////////////////

module Router
	import pkg_top::*;
	import pkg_mpu::*;
	import pkg_tpu::*;
#(
	parameter int	ROW_ID		= 0,
	parameter int	CLM_ID		= 0
)(
	input						clock,
	input						reset,
	input						I_Req,					//Request from Forward Path
	input						I_Rls,					//Release Token from Forward Path
	input	[WIDTH_DATA-1:0]	I_Data,					//Data from Forward Path
	output						O_Req_A,				//Request for Branch Path
	output						O_Req_B,				//Request for Branch Path
	output						O_Rls_A,				//Release for Branch Path
	output						O_Rls_B,				//Release for Branch Path
	output	[WIDTH_DATA-1:0]	O_Data_A,				//Data for Branch Path
	output	[WIDTH_DATA-1:0]	O_Data_B,				//Data for Branch Path
	output						O_Req,					//Request for Backward Path
	output						O_Rls,					//Release Token for Backward Path
	output	[WIDTH_DATA-1:0]	O_Data,					//Data for Backward Path
	input						I_Req_A,				//Request from Branch
	input						I_Req_B,				//Request from Branch
	input						I_Rls_A,				//Release Token from Branch
	input						I_Rls_B,				//Release Token from Branch
	input	[WIDTH_DATA-1:0]	I_Data_A,				//Data from Branch
	input	[WIDTH_DATA-1:0]	I_Data_B				//Data from Branch
);


	logic	[WIDTH_DATA/4:0]	ID_Row;
	logic	[WIDTH_DATA/4:0]	ID_Clm;

	logic	[WIDTH_DATA/2:0]	MyID;
	logic	[WIDTH_DATA/2:0]	ID;

	//logic	[WIDTH_DATA-1:0]	BranchID;

	logic						is_Matched;


	logic						Req_A;
	logic						Req_B;
	logic						Rls_A;
	logic						Rls_B;

	logic						Req;
	logic						Rls;

	logic	[WIDTH_DATA-1:0]	DataA;
	logic	[WIDTH_DATA-1:0]	DataB;

	logic	[WIDTH_DATA-1:0]	Data;

	logic						Run;
	logic						R_is_Matched;

	assign ID_Row				= ROW_ID;
	assign ID_Clm				= CLM_ID;
	assign ID					= { ID_Row, ID_Clm };
	assign is_Matched			= I_Req & ( I_Data == ID );

	assign O_Req_A				= Req_A;
	assign O_Rls_A				= Rls_A;
	assign O_Data_A				= DataA;

	assign O_Req_B				= Req_B;
	assign O_Rls_B				= Rls_B;
	assign O_Data_B				= DataB;


	assign O_Req				= Req;
	assign O_Rls				= Rls;
	assign O_Data				= Data;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			MyID			<= 0;
		end
		else if ( I_Req & ~Run ) begin
			MyID			<= I_Data[WIDTH_DATA/2-1:0];
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_is_Matched	<= 1'b0;
		end
		else begin
			R_is_Matched	<= is_Matched;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req				<= 1'b0;
		end
		else if ( ~Run ) begin
			Req				<= 1'b0;
		end
		else if ( Run & ( I_Req_A | I_Req_B ) ) begin
			Req				<= ( R_is_Matched ) ? I_Req_B : I_Req_A;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Rls				<= 1'b0;
		end
		else if ( ~Run ) begin
			Rls				<= 1'b0;
		end
		else if ( Run & ( I_Rls_A | I_Rls_B ) ) begin
			Rls				<= ( R_is_Matched ) ? I_Rls_B : I_Rls_A;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Data			<= 0;
		end
		else if ( Run & ( I_Req_A | I_Req_B ) ) begin
			Data			<= ( R_is_Matched ) ? I_Data_B : I_Data_A;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req_A			<= 1'b0;
		end

		else if ( I_Req & ~Run & ~is_Matched ) begin
			Req_A			<= 1'b1;
		end
		else if ( ~Run ) begin
			Req_A			<= 1'b0;
		end
		else if ( Run & ~R_is_Matched ) begin
			Req_A			<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req_B			<= 1'b0;
		end
		else if ( I_Req & ~Run & is_Matched ) begin
			Req_B			<= 1'b1;
		end
		else if ( ~Run ) begin
			Req_B			<= 1'b0;
		end
		else if ( Run & R_is_Matched ) begin
			Req_B			<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Rls_A			<= 1'b0;
		end
		else if ( I_Rls & ~Run & ~is_Matched ) begin
			Rls_A			<= 1'b1;
		end
		else if ( ~Run ) begin
			Rls_A			<= 1'b0;
		end
		else if ( Run & ~R_is_Matched ) begin
			Rls_A			<= I_Rls;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Rls_B			<= 1'b0;
		end
		else if ( I_Rls & ~Run & is_Matched ) begin
			Rls_B			<= 1'b1;
		end
		else if ( ~Run ) begin
			Rls_B			<=1'b0;
		end
		else if ( Run & R_is_Matched ) begin
			Rls_B			<= I_Rls;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			DataA			<= 0;
		end
		else if ( I_Req & ~Run ) begin
			DataA			<= I_Data;
		end
		else if ( I_Req & Run & ~R_is_Matched ) begin
			DataA			<= I_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			DataB			<= 0;
		end
		else if ( I_Req & ~Run ) begin
			DataB			<= { I_Data[WIDTH_DATA/2-1:0], I_Data[WIDTH_DATA-1:WIDTH_DATA/2] };
		end
		else if ( I_Req & Run & R_is_Matched ) begin
			DataB			<= I_Data;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run				<= 1'b0;
		end
		else if ( I_Rls ) begin
			Run				<= 1'b0;
		end
		else if ( I_Req ) begin
			Run				<= 1'b1;
		end
	end

endmodule