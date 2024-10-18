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

module AuxRegs #(
	import	LANE_ID				= 0
)(
	input						clock,
	input						reset,
	input						I_Stall,				//Stall Request
	input	id_t				I_ThreadID,
	input						I_Re,					//Read Enable
	input						I_We,					//Write Enable
	input	pipe_index_t		I_Src_Command,			//Command
	input	pipe_exe_tmp_t		I_Dst_Command,			//Command
	output						O_We_p0,
	output						O_We_p1,
	output						O_Re_p0,
	output						O_Re_p1,
	output						O_Re_c
);


	data_t						Constant[1:0];

	logic						RegMove_Rd;
	logic						RegMove_Wt;

	logic						Re_c;
	logic						We_c;


	assign RegMove_Rd			= I_Re & ( I_Src_Command.instr.op.OpType == 2'b00 ) &
									( I_Src_Command.instr.op.OpClass == 2'b11 ) &
									( I_Src_Command.instr.op.OpCode == 2'b10 );

	assign RegMove_Wt			= I_We & ( I_Src_Command.instr.op.OpType == 2'b00 ) &
									( I_Src_Command.instr.op.OpClass == 2'b11 ) &
									( I_Src_Command.instr.op.OpCode == 2'b11 );


	assign O_We_p0				= RegMove_Wt & I_Dst_Command.dst.v & ( I_Dst_Command.dst.idx[0] == 1'b0 );
	assign O_We_p1				= RegMove_Wt & I_Dst_Command.dst.v & ( I_Dst_Command.dst.idx[0] == 1'b1 );

	assign O_Re_p0				= RegMove_Rd & I_Src_Command.src1.v & ( I_Src_Command.src1.idx[0] == 1'b0 );
	assign O_Re_p1				= RegMove_Rd & I_Src_Command.src1.v & ( I_Src_Command.scr1.idx[0] == 1'b1 );

	assign We_c					= RegMove_Wt & ~( O_We_p0 | O_We_p1 );
	assign Re_c					= RegMove_Rd & ~( O_Re_p0 | O_Re_p1 );
	assign O_Re_c				= Re_c

endmodule