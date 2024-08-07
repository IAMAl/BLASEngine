///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	Dispatch_TPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module Dispatch_TPU (
	input	command_t			I_Command,
	output	commit_t			O_S_Command,
	output	commit_t			O_V_Command
);


	logic						Sel_Unit;


	assign Sel_Unit				= I_Command.Sel_Unit;

	assign O_S_Command.valid	= I_Command.v &  ~Sel_Unit;
	assign O_S_Command.OpType	= ( Sel_Unit ) ? '0 :	I_Command.OpType;
	assign O_S_Command.OpClass	= ( Sel_Unit ) ? '0 :	I_Command.OpClass;
	assign O_S_Command.OpCode 	= ( Sel_Unit ) ? '0 :	I_Command.OpCode;
	assign O_S_Command.v_dst	= ( Sel_Unit ) ? '0 :	I_Command.v_dst;
	assign O_S_Command.v_src1	= ( Sel_Unit ) ? '0 :	I_Command.v_src1;
	assign O_S_Command.v_src2	= ( Sel_Unit ) ? '0 :	I_Command.v_src2;
	assign O_S_Command.v_src3 	= ( Sel_Unit ) ? '0 :	I_Command.v_src3;
	assign O_S_Command.v_src4	= ( Sel_Unit ) ? '0 :	I_Command.v_src4;
	assign O_S_Command.slice1	= ( Sel_Unit ) ? '0 :	I_Command.slice1;
	assign O_S_Command.slice2 	= ( Sel_Unit ) ? '0 :	I_Command.slice2;
	assign O_S_Command.slice3	= ( Sel_Unit ) ? '0 :	I_Command.slice3;
	assign O_S_Command.IdxLength= ( Sel_Unit ) ? '0 :	I_Command.IdxLength;
	assign O_S_Command.DstIdx	= ( Sel_Unit ) ? '0 :	I_Command.DstIdx;
	assign O_S_Command.SrcIdx1	= ( Sel_Unit ) ? '0 :	I_Command.SrcIdx1;
	assign O_S_Command.SrcIdx2	= ( Sel_Unit ) ? '0 :	I_Command.SrcIdx2;
	assign O_S_Command.SrcIdx3	= ( Sel_Unit ) ? '0 :	I_Command.SrcIdx3;
	assign O_S_Command.Imm_Data	= ( Sel_Unit ) ? '0 :	;//ToDo

	assign O_V_Command.valid	= I_Command.v &  Sel_Unit;
	assign O_V_Command.OpType	= ( Sel_Unit ) ? I_Command.OpType     : '0;
	assign O_V_Command.OpClass	= ( Sel_Unit ) ? I_Command.OpClass    : '0;
	assign O_V_Command.OpCode	= ( Sel_Unit ) ? I_Command.OpCode     : '0;
	assign O_V_Command.v_dst	= ( Sel_Unit ) ? I_Command.v_dst      : '0;
	assign O_V_Command.v_src1 	= ( Sel_Unit ) ? I_Command.v_src1     : '0;
	assign O_V_Command.v_src2	= ( Sel_Unit ) ? I_Command.v_src2     : '0;
	assign O_V_Command.v_src3	= ( Sel_Unit ) ? I_Command.v_src3     : '0;
	assign O_V_Command.v_src4	= ( Sel_Unit ) ? I_Command.v_src4     : '0;
	assign O_V_Command.slice1	= ( Sel_Unit ) ? I_Command.slice1     : '0;
	assign O_V_Command.slice2	= ( Sel_Unit ) ? I_Command.slice2     : '0;
	assign O_V_Command.slice3	= ( Sel_Unit ) ? I_Command.slice3     : '0;
	assign O_V_Command.IdxLength= ( Sel_Unit ) ? I_Command.IdxLength  : '0;
	assign O_V_Command.DstIdx	= ( Sel_Unit ) ? I_Command.DstIdx     : '0;
	assign O_V_Command.SrcIdx1	= ( Sel_Unit ) ? I_Command.SrcIdx1    : '0;
	assign O_V_Command.SrcIdx2	= ( Sel_Unit ) ? I_Command.SrcIdx2    : '0;
	assign O_V_Command.SrcIdx3	= ( Sel_Unit ) ? I_Command.SrcIdx3    : '0;
	assign O_V_Command.Imm_Data	= ( Sel_Unit ) ? //ToDo : 0;

endmodule