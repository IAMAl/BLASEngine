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
(
	input						clock,
	input						reset,
	input						I_Req,
	input						I_Rls,
	input	[WIDTH_DATA-1:0]	I_Data,
	output						O_Req_A,
	output						O_Req_B,
	output	[WIDTH_DATA-1:0]	O_Data_A,
	output	[WIDTH_DATA-1:0]	O_Data_B,
	output						O_Req;
	output						O_Rls;
	output	[WIDTH_DATA-1:0]	O_Data,
	input						I_Req_A,
	input						I_Req_B,
	input						I_Rls_A,
	input						I_Rls_B,
	input	[WIDTH_DATA-1:0]	I_Data_A,
	input	[WIDTH_DATA-1:0]	I_Data_B
);

	logic	[WIDTH_DATA/2:0]	MyID;
	logic	[WIDTH_DATA/2:0]	ID;

	logic	[WIDTH_DATA-1:]		BranchID;

	logic						is_Matched;


	logic						Req_A;
	logic						Req_B;

	logic	[WIDTH_DATA-1:0]	DataA;
	logic	[WIDTH_DATA-1:0]	DataB;

	logic						Req;
	logic	[[WIDTH_DATA-1:0]]	Data;

	logic						Run;
	logic						R_is_Matched;


	assign O_Req_A			= Req_A;
	assign O_Rls_A			= Rls_A;
	assign O_Data_A			= DataA;

	assign O_Req_B			= Req_B;
	assign O_Rls_B			= Rls_B;
	assign O_Data_B			= DataB;


	assign O_Req			= Req
	assign O_Rls			= Rls;
	assign O_Data			= Data;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			MyID				<= 0;
		end
		else if ( I_Req ~Run ) begin
			MyID				<= I_Data[WIDTH_DATA/2-1:0];
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req					<= 1'b0;
		end
		else if ( ~Run ) begin
			Req					<= 1'b0;
		end
		else if ( Run & ( I_Req_A | I_Req_B ) ) begin
			Req					<= ( R_is_Matched ) ? I_Req_B : I_Req_A;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Rls					<= 1'b0;
		end
		else if ( ~Run ) begin
			Req					<= 1'b0;
		end
		else if ( Run & ( I_Rls_A | I_Rls_B ) ) begin
			Rls					<= ( R_is_Matched ) ? I_Rls_B : I_Rls_A;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Data				<= 0;
		end
		else if ( Run & ( I_Req_A | I_Req_B ) ) begin
			Data				<= ( R_is_Matched ) ? I_Data_B : I_Data_A;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req_A				<=1'b0;
		end

		else if ( I_Req ~Run & ~is_Matched ) begin
			Req_A				<= 1'b1;
		end
		else if ( ~Run ) begin
			Req_A				<=1'b0;
		end
		else if ( Run ~R_is_Matched ) begin
			Req_A				<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req_B				<= 1'b0;
		end
		else if ( I_Req ~Run & is_Matched ) begin
			Req_B				<= 1'b1;
		end
		else if ( ~Run ) begin
			Req_B				<=1'b0;
		end
		else if ( Run R_is_Matched ) begin
			Req_B				<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Rls_A				<=1'b0;
		end
		else if ( I_Rls & ~Run & ~is_Matched ) begin
			Rls_A				<= 1'b1;
		end
		else if ( ~Run ) begin
			Rls_A				<=1'b0;
		end
		else if ( Run ~R_is_Matched ) begin
			Rls_A				<= I_Rls;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Rls_B				<= 1'b0;
		end
		else if ( I_Rls ~Run & is_Matched ) begin
			Rls_B				<= 1'b1;
		end
		else if ( ~Run ) begin
			Rls_B				<=1'b0;
		end
		else if ( Run R_is_Matched ) begin
			Rls_B				<= I_Rls;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			DataA				<= 0;
		end
		else if ( I_Req ~Run ) begin
			DataA				<= I_Data;
		end
		else if ( I_Req & Run ~R_is_Matched ) begin
			DataA				<= I_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			DataB				<= 0;
		end
		else if ( I_Req ~Run ) begin
			DataB				<= { I_Data[WIDTH_DATA/2-1:0], I_Data[WIDTH_DATA:WIDTH_DATA/2] };
		end
		else if ( I_Req & Run R_is_Matched ) begin
			DataB				<= I_Data;
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