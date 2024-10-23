///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	AuxRegs
///////////////////////////////////////////////////////////////////////////////////////////////////

module AuxRegs
import pkg_tpu::*;
import pkg_mpu::*;
#(
	parameter int LANE_ID		= 0
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall Request
	input	id_t				I_ThreadID,				//Thread ID
	input						I_Re,					//Read Enable
	input						I_We,					//Write Enable
	input	pipe_index_t		I_Src_Command,			//Command
	input	pipe_exe_tmp_t		I_Dst_Command,			//Command
	output						O_Re_p0,				//Read-Enable Pipeline Reg
	output						O_Re_p1,				//Read-Enable Pipeline Reg
	output						O_Re_c,					//Read-Enable Constant Reg
	input	data_t				I_Data,					//Data from WB path
	output	data_t				O_Data,					//Data too Register-Read path
	input						I_SWe,					//Write-Enable for Scalar Data
	input	data_t				I_Scalar_Data,			//Write into Scalar Data
	output	data_t				O_Scalar_Data			//Read from Scalar Data
);


	logic						RegMove_Rd;
	logic						RegMove_Wt;

	logic						Re_c;
	logic						We_c;

	logic						Re_s;
	logic						We_s;

	data_t						SData_W;
	data_t						SData_R;


	assign RegMove_Rd			= I_Re & ( I_Src_Command.op.OpType == 2'b00 ) &
									( I_Src_Command.op.OpClass == 2'b11 ) &
									( I_Src_Command.op.OpCode == 2'b10 );

	assign RegMove_Wt			= I_We & ( I_Src_Command.op.OpType == 2'b00 ) &
									( I_Src_Command.op.OpClass == 2'b11 ) &
									( I_Src_Command.op.OpCode == 2'b11 );

	assign O_Re_p0				= RegMove_Rd & I_Src_Command.src1.v & ( I_Src_Command.src1.idx == 0 );
	assign O_Re_p1				= RegMove_Rd & I_Src_Command.src1.v & ( I_Src_Command.src1.idx == 1 );

	assign We_c					= RegMove_Wt;
	assign Re_c					= RegMove_Rd & ~( O_Re_p0 | O_Re_p1 );
	assign O_Re_c				= Re_c;


	assign We_s					= I_We & ( I_Src_Command.op.OpType == 2'b00 ) &
									( I_Src_Command.op.OpClass == 2'b11 ) &
									( I_Src_Command.op.OpCode == 2'b11 )  &
									( I_Src_Command.src1.idx == 8 );

	assign Re_s					= I_We & ( I_Src_Command.op.OpType == 2'b00 ) &
									( I_Src_Command.op.OpClass == 2'b11 ) &
									( I_Src_Command.op.OpCode == 2'b10 )  &
									( I_Src_Command.src1.idx == 8 );


	assign O_Data				= ( Re_s ) ? SData_R : '0;
	assign O_Scalar_Data		= SData_W;


	//// Scalar Data Register
	// Scalar Data Register for Writing
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			SData_W				<= '0;
		end
		else if ( We_s ) begin
			SData_W				<= I_Data;
		end
	end

	// Scalar Data REgister for Reading
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			SData_R				<= '0;
		end
		else if ( I_SWe ) begin
			SData_R				<= I_Scalar_Data;
		end
	end

endmodule