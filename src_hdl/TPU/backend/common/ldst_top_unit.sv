
module LdStUnit (
	input						clock,
	input						reset,
	input						I_Stall,
	input						I_Req,
	input	commant_t			I_Command,
	input	dst_t				I_WB_Dst,	//ToDo
	input	data_t				I_Src_Src_Data1,
	input	data_t				I_Src_Src_Data2,
	input	data_t				I_Src_Src_Data3,
	input	ldst_t				O_LdSt,
	input	data_t				I_Ld_Data,
	input	data_t				O_St_Data,
	input						I_Ld_Ready,
	input						I_Ld_Grant,
	input						I_St_Ready,
	input						I_St_Grant,
	input	index_t				O_WB_Index,
	input	data_t				O_WB_Data,
	input	issue_no_t			O_WB_IssueNo,
	input						O_LdSt_Done1,
	input						O_LdSt_Done2
);


	logic						Ld_Req				[1:0];
	logic						St_Req				[1:0];

	data_t						Ld_Data				[1:0];
	data_t						St_Data				[1:0];

	address_t					Ld_Length			[1:0];
	address_t					St_Length			[1:0];
	address_t					Ld_Stride			[1:0];
	address_t					St_Stride			[1:0];
	address_t					Ld_Base				[1:0];
	address_t					St_Base				[1:0];

	logic						Ld_Commit_Req		[1:0];
	logic						St_Commit_Req		[1:0];

	issue_no_t					Ld_Commit_No		[1:0];
	issue_no_t					St_Commit_No		[1:0];

	logic						Ld_Stall			[1:0];
	logic						St_Stall			[1:0];

	TYPE						Ld_Token			[1:0];
	TYPE						St_Token			[1:0];

	issue_no_t					LifeLd				[1:0];
	issue_no_t					LifeSt				[1:0];


	assign LifeLd[0]			= I_Issue_No - Ld_Commit_No[0];
	assign LifeLd[1]			= I_Issue_No - Ld_Commit_No[1];
	assign LifeSt[0]			= I_Issue_No - St_Commit_No[0];
	assign LifeSt[1]			= I_Issue_No - St_Commit_No[1];

	assign Ld_Token[0]			= ;//ToDo
	assign Ld_Token[1]			= ;//ToDo

	assign St_Token[0]			= ;//ToDo
	assign St_Token[1]			= ;//ToDo


	assign Ld_Req[0]			= I_Command.instr.v & ( I_Command.instr.op.OPType == 2'b11 ) & ~I_Command.instr.op.OpClass[1] & ~I_Command.instr.op.OpClass[0];
	assign Ld_Req[1]			= I_Command.instr.v & ( I_Command.instr.op.OPType == 2'b11 ) & ~I_Command.instr.op.OpClass[1] &  I_Command.instr.op.OpClass[0];

	assign St_Req[0]			= I_Command.instr.v & ( I_Command.instr.op.OPType == 2'b11 ) &  I_Command.instr.op.OpClass[1] & ~I_Command.instr.op.OpClass[0];
	assign St_Req[1]			= I_Command.instr.v & ( I_Command.instr.op.OPType == 2'b11 ) &  I_Command.instr.op.OpClass[1] &  I_Command.instr.op.OpClass[0];

	assign St_Data[0]			= ( Sel_St1 ) ?		I_Src_Src_Data1 : 0;
	assign St_Data[1]			= ( Sel_St2 ) ?		I_Src_Src_Data1 : 0;


	assign O_LdSt.ld.req		= ( Sel_Ld2 ) ?		Ld_Req[1] :
									( Sel_Ld1 ) ?	Ld_Req[0] :
													0;

	assign O_LdSt.ld.len		= ( Sel_Ld2 ) ?		Ld_Length[1] :
									( Sel_Ld1 ) ?	Ld_Length[0] :
													0;

	assign O_LdSt.ld.stride		= ( Sel_Ld2 ) ?		Ld_Stride[1] :
									( Sel_Ld1 ) ?	Ld_Stride[0] :
													0;

	assign O_LdSt.ld.base		= ( Sel_Ld2 ) ?		Ld_Base[1] :
									( Sel_Ld1 ) ?	Ld_Base[0] :
													0;


	assign O_LdSt.st.req		= ( Sel_St2 ) ?		St_Req[1] :
									( Sel_St1 ) ?	St_Req[0] :
													0;

	assign O_LdSt.st.len		= ( Sel_St2 ) ?		St_Length[1] :
									( Sel_St1 ) ?	St_Length[0] :
													0;

	assign O_LdSt.st.stride		= ( Sel_St2 ) ?		St_Stride[1] :
									( Sel_St1 ) ?	St_Stride[0] :
													0;

	assign O_LdSt.st.base		= ( Sel_St2 ) ?		St_Base[1] :
									( Sel_St1 ) ?	St_Base[0] :
													0;


	assign O_LdSt_Done1			= Ld_Commit_Req[0] | St_Commit_Req[0];
	assign O_LdSt_Done2			= Ld_Commit_Req[1] | St_Commit_Req[1];


	assign O_WB_Index			= ;//ToDo

	assign O_WB_Data			= ( Sel_Ld2 ) ?		Ld_Data[1] :
									( Sel_Ld1 ) ?	Ld_Data[0] :
									( Sel_Math ) ?	Math_Data :
													0;

	assign O_WB_IssueNo			= ( Sel_Ld2 ) ?		Ld_Commit_No[1] :
									( Sel_Ld1 ) ?	Ld_Commit_No[0] :
									( Sel_Math ) ?	Math_Commit_No :
													0;


	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				pipe_exe_tmp_t				)
	) ld_unit_odd
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Grant(			I_Ld_Grant					),
		.I_Valid(				),//ToDo
		.I_Data(			I_Ld_Data					),
		.O_Data(			Ld_Data[1]					),
		.I_Term(				),//ToDo
		.I_Req(				Ld_Req[1]					),
		.I_Length(			I_Src_Src_Data1				),
		.I_Stride(			I_Src_Src_Data2				),
		.I_Base(			I_Src_Src_Data3				),
		.O_Req(				Ld_Req[1]					),
		.O_Length(			Ld_Length[1]				),
		.O_Stride(			Ld_Stride[1]				),
		.O_Base(			Ld_Base[1]					),
		.I_Token(			Ld_Token[1]					),
		.O_Commit_Req(		Ld_Commit_Req[1]			),
		.O_Commit_No(		Ld_Commit_No[1]				),
		.O_Stall(			Ld_Stall[1]					)
	);

	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				pipe_exe_tmp_t				)
	) st_unit_odd
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Grant(			I_St_Grant					),
		.I_Valid(				),//ToDo
		.I_Data(			St_Data[1]					),
		.O_Data(			O_St_Data[1]				),
		.I_Term(				),//ToDo
		.I_Req(				St_Req[1]					),
		.I_Length(			I_Src_Src_Data1				),
		.I_Stride(			I_Src_Src_Data2				),
		.I_Base(			I_Src_Src_Data3				),
		.O_Req(				St_Req[1]					),
		.O_Length(			St_Length[1]				),
		.O_Stride(			St_Stride[1]				),
		.O_Base(			St_Base[1]					),
		.I_Token(			St_Token[1]					),
		.O_Commit_Req(		St_Commit_Req[1]			),
		.O_Commit_No(		St_Commit_No[1]				),
		.O_Stall(			St_Stall[1]					)
	);


	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				pipe_exe_tmp_t				)
	) ld_unit_evn
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Grant(			I_Ld_Grant					),
		.I_Valid(				),//ToDo
		.I_Data(			I_Ld_Data					),
		.O_Data(			Ld_Data[0]					),
		.I_Term(				),//ToDo
		.I_Req(				Ld_Req[0]					),
		.I_Length(			I_Src_Src_Data1				),
		.I_Stride(			I_Src_Src_Data2				),
		.I_Base(			I_Src_Src_Data3				),
		.O_Req(				Ld_Req[0]					),
		.O_Length(			Ld_Length[0]				),
		.O_Stride(			Ld_Stride[0]				),
		.O_Base(			Ld_Base[0]					),
		.I_Token(			Ld_Token[0]					),
		.O_Commit_Req(		Ld_Commit_Req[0]			),
		.O_Commit_No(		Ld_Commit_No[0]				),
		.O_Stall(			Ld_Stall[0]					)
	);

	ldst_unit #(
		.DEPTH_BUFF(		16							),
		.DEPTH_BUFF_LDST(	DEPTH_BUFF_LDST				),
		.TYPE(				pipe_exe_tmp_t				)
	) st_unit_evn
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_Stall(			I_Stall						),
		.I_Grant(			I_St_Grant					),
		.I_Valid(				),//ToDo
		.I_Data(			St_Data[0]					),
		.O_Data(			O_St_Data					),
		.I_Term(				),//ToDo
		.I_Req(				St_Req[0]					),
		.I_Length(			I_Src_Src_Data1				),
		.I_Stride(			I_Src_Src_Data2				),
		.I_Base(			I_Src_Src_Data3				),
		.O_Req(				St_Req[0]					),
		.O_Length(			St_Length[0]				),
		.O_Stride(			St_Stride[0]				),
		.O_Base(			St_Base[0]					),
		.I_Token(			St_Token[0]					),
		.O_Commit_Req(		St_Commit_Req[0]			),
		.O_Commit_No(		St_Commit_No[0]				),
		.O_Stall(			St_Stall[0]					)
	);

endmodule