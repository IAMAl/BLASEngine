module Issue_Command (
	input	logic				I_Sel_Unit;
	input	commant_t			I_Command,
	output	commit_t			O_S_Command,
	output	commit_t			O_V_Command
);


	assign O_S_Command.valid	= I_Command.v &  ~I_Sel_Unit;
	assign O_S_Command.OpType	= ( I_Sel_Unit ) ? 0 : I_Command.OpType;
	assign O_S_Command.OpClass	= ( I_Sel_Unit ) ? 0 : I_Command.OpClass;
	assign O_S_Command.OpCode 	= ( I_Sel_Unit ) ? 0 : I_Command.OpCode;
	assign O_S_Command.v_dst	= ( I_Sel_Unit ) ? 0 : I_Command.v_dst;
	assign O_S_Command.v_src1	= ( I_Sel_Unit ) ? 0 : I_Command.v_src1;
	assign O_S_Command.v_src2	= ( I_Sel_Unit ) ? 0 : I_Command.v_src2;
	assign O_S_Command.v_src3 	= ( I_Sel_Unit ) ? 0 : I_Command.v_src3;
	assign O_S_Command.v_src4	= ( I_Sel_Unit ) ? 0 : I_Command.v_src4;
	assign O_S_Command.slice1	= ( I_Sel_Unit ) ? 0 : I_Command.slice1;
	assign O_S_Command.slice2 	= ( I_Sel_Unit ) ? 0 : I_Command.slice2;
	assign O_S_Command.slice3	= ( I_Sel_Unit ) ? 0 : I_Command.slice3;
	assign O_S_Command.IdxLength= ( I_Sel_Unit ) ? 0 : I_Command.IdxLength;
	assign O_S_Command.DstIdx	= ( I_Sel_Unit ) ? 0 : I_Command.DstIdx;
	assign O_S_Command.SrcIdx1	= ( I_Sel_Unit ) ? 0 : I_Command.SrcIdx1;
	assign O_S_Command.SrcIdx2	= ( I_Sel_Unit ) ? 0 : I_Command.SrcIdx2;
	assign O_S_Command.SrcIdx3	= ( I_Sel_Unit ) ? 0 : I_Command.SrcIdx3;
	assign O_S_Command.Imm_Data	= ( I_Sel_Unit ) ? 0 : ;//ToDo

	assign O_V_Command.valid	= I_Command.v &  I_Sel_Unit;
	assign O_V_Command.OpType	= ( I_Sel_Unit ) ? I_Command.OpType     : 0;
	assign O_V_Command.OpClass	= ( I_Sel_Unit ) ? I_Command.OpClass    : 0;
	assign O_V_Command.OpCode	= ( I_Sel_Unit ) ? I_Command.OpCode     : 0;
	assign O_V_Command.v_dst	= ( I_Sel_Unit ) ? I_Command.v_dst      : 0;
	assign O_V_Command.v_src1 	= ( I_Sel_Unit ) ? I_Command.v_src1     : 0;
	assign O_V_Command.v_src2	= ( I_Sel_Unit ) ? I_Command.v_src2     : 0;
	assign O_V_Command.v_src3	= ( I_Sel_Unit ) ? I_Command.v_src3     : 0;
	assign O_V_Command.v_src4	= ( I_Sel_Unit ) ? I_Command.v_src4     : 0;
	assign O_V_Command.slice1	= ( I_Sel_Unit ) ? I_Command.slice1     : 0;
	assign O_V_Command.slice2	= ( I_Sel_Unit ) ? I_Command.slice2     : 0;
	assign O_V_Command.slice3	= ( I_Sel_Unit ) ? I_Command.slice3     : 0;
	assign O_V_Command.IdxLength= ( I_Sel_Unit ) ? I_Command.IdxLength  : 0;
	assign O_V_Command.DstIdx	= ( I_Sel_Unit ) ? I_Command.DstIdx     : 0;
	assign O_V_Command.SrcIdx1	= ( I_Sel_Unit ) ? I_Command.SrcIdx1    : 0;
	assign O_V_Command.SrcIdx2	= ( I_Sel_Unit ) ? I_Command.SrcIdx2    : 0;
	assign O_V_Command.SrcIdx3	= ( I_Sel_Unit ) ? I_Command.SrcIdx3    : 0;
	assign O_V_Command.Imm_Data	=;//ToDo

endmodule