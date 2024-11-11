///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	TPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module TPU
	import pkg_mpu::*;
	import pkg_tpu::*;
	import pkg_tpu::instr_t;
(
	input						clock,
	input						reset,
	input						I_En_Exe,				//Enable Executing
	input						I_Req,					//Request from MPU
	input	mpu_issue_no_t		I_IssueNo,				//Thread's Issue No
	input	instr_t				I_Instr,				//Instructions from MPU
	output	s_ldst_t			O_S_LdSt,				//Load/Store Command
	input	s_ldst_data_t		I_S_Ld_Data,			//Loaded Data from DMem
	output	s_ldst_data_t		O_S_St_Data,			//Storing Data to Dmem
	input	[1:0]				I_S_Ld_Ready,			//Flag: Ready
	input	[1:0]				I_S_Ld_Grant,			//Flag: Grant for Request
	input	[1:0]				I_S_St_Ready,			//Flag: Ready
	input	[1:0]				I_S_St_Grant,			//Flag: Grant
	input	[1:0]				I_S_End_Access,			//Flag: End of Access
	output	v_ldst_t			O_V_LdSt,				//Load/Store Command
	input	v_ldst_data_t		I_V_Ld_Data,			//Loaded Data
	output	v_ldst_data_t		O_V_St_Data,			//Storing Data
	input	v_2b_t				I_V_Ld_Ready,			//Flag:	Ready
	input	v_2b_t				I_V_Ld_Grant,			//Flag: Grant
	input	v_2b_t				I_V_St_Ready,			//Flag: Ready
	input	v_2b_t				I_V_St_Grant,			//Flag: Grant
	input	v_2b_t				I_V_End_Access,			//Flag: End of Access
	output	mpu_issue_no_t		O_IssueNo,				//Thread's Issue No
	output						O_Term,					//Flag: Termination
	output						O_Nack					//Flag: Not-Acknowledge
);


	id_t						ThreadID;

	data_t						In_Scalar_Data;
	data_t						Out_Scalar_Data;

	state_t						S_Status;

	v_ready_t					Lane_En;
	pipe_index_t				V_Command;
	v_ready_t					V_Status;

	logic						Commit_Req;
	issue_no_t					Commit_No;
	logic						Commit_Grant;

	logic						Term;


	logic						Empty;
	logic						Full;

	logic						Wr_End;
	logic						We_Instr;
	instr_t						Wr_Instr;

	logic						Re_Instr;
	instr_t						Rd_Instr;
	i_address_t					Rd_Address;


	//// Service Management Unit
	FrontEnd FrontEnd (
		.clock(				clock					),
		.reset(				reset					),
		.I_En_Exe(			I_En_Exe				),
		.I_Full(			Full					),
		.I_Term(			Term					),
		.I_Nack(			Full					),
		.I_Req(				I_Req					),
		.I_Instr(			I_Instr					),
		.I_IssueNo(			I_IssueNo				),
		.O_We(				We_Instr				),
		.O_Wr_End(			Wr_End					),
		.O_ThreadID(		ThreadID				),
		.O_Instr(			Wr_Instr				),
		.O_Term(			O_Term					),
		.O_IssueNo(			O_IssueNo				),
		.O_Nack(			O_Nack					)
	);


	//// Instruction Memory
	IMem #(
		.IMEM_SIZE(			INSTR_MEM_SIZE			)
	) Instr_Mem
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			We_Instr				),
		.I_End_St(			Wr_End					),
		.I_Instr(			Wr_Instr				),
		.I_Req_Ld(			Re_Instr				),
		.I_End_Ld(			Term					),
		.O_Instr(			Rd_Instr				),
		.I_Ld_Address(		Rd_Address				),
		.O_Empty(			Empty					),
		.O_Full(			Full					)
	);


	//// Scalar Unit
	Scalar_Unit Scalar_Unit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Empty(			Empty					),
		.I_En(				I_En_Exe				),
		.O_Re_Instr(		Re_Instr				),
		.O_Rd_Address(		Rd_Address				),
		.I_ThreadID(		ThreadID				),
		.I_Instr(			Rd_Instr				),
		.I_Commit_Req_V(	Commit_Req				),
		.I_Commit_No_V(		Commit_No				),
		.O_Commit_Grant_V(	Commit_Grant			),
		.I_Scalar_Data(		In_Scalar_Data			),
		.O_Scalar_Data(		Out_Scalar_Data			),
		.O_LdSt(			O_S_LdSt				),
		.I_Ld_Data(			I_S_Ld_Data				),
		.O_St_Data(			O_S_St_Data				),
		.I_Ld_Ready(		I_S_Ld_Ready			),
		.I_Ld_Grant(		I_S_Ld_Grant			),
		.I_St_Ready(		I_S_St_Ready			),
		.I_St_Grant(		I_S_St_Grant			),
		.I_End_Access(		I_S_End_Access			),
		.O_V_Command(		V_Command				),
		.I_V_State(			V_Status				),
		.O_Lane_En(			Lane_En					),
		.O_Status(			S_Status				),
		.O_Term(			Term					)
	);


	//// Vector Unit
	Vector_Unit Vector_Unit (
		.clock(				clock					),
		.reset(				reset					),
		.I_En_Lane(			Lane_En					),
		.I_ThreadID(		ThreadID				),
		.I_Command(			V_Command				),
		.I_Scalar_Data(		Out_Scalar_Data			),
		.O_Scalar_Data(		In_Scalar_Data			),
		.O_LdSt(			O_V_LdSt				),
		.I_Ld_Data(			I_V_Ld_Data				),
		.O_St_Data(			O_V_St_Data				),
		.I_End_Access(		I_V_End_Access			),
		.I_Ld_Ready(		I_V_Ld_Ready			),
		.I_Ld_Grant(		I_V_Ld_Grant			),
		.I_St_Ready(		I_V_St_Ready			),
		.I_St_Grant(		I_V_St_Grant			),
		.O_Commit_Req(		Commit_Req				),
		.O_Commit_No(		Commit_No				),
		.I_Commit_Grant(	Commit_Grant			),
		.O_Status(			V_Status				)
	);

endmodule