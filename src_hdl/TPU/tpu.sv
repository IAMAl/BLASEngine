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


	logic						Ack_St;

	instr_t						Buff_Instr;
	logic						We_Buff;
	logic						Re_Buff;
	logic 						Buff_Full;
	logic						Buff_Empty;
	instr_t						Instr;

	id_t						Buff_ThreadID;
	logic						IDBuff_We;
	logic						IDBuff_Re;
	logic						IDBuff_Full;
	logic						IDBuff_Empty;
	id_t						ThreadID;

	data_t						In_Scalar_Data;
	data_t						Out_Scalar_Data;

	state_t						S_Status;

	command_t					V_Command;
	v_ready_t					En_Lane;
	v_ready_t					V_Status;

	logic						Commit_Req_V;;
	logic						Commit_Grant;

	logic						Term;


	//// Service Management UNit
	FrontEnd FrontEnd (
		.clock(				clock					),
		.reset(				reset					),
		.I_En_Exe(			I_En_Exe				),
		.I_Full(			Buff_Full				),
		.I_Term(			Term					),
		.I_Nack(			~Ack_St					),
		.I_Req(				I_Req					),
		.I_Instr(			I_Instr					),
		.I_IssueNo(			I_IssueNo				),
		.O_We(				We_Buff					),
		.O_ThreadID(		Buff_ThreadID			),
		.O_Instr(			Buff_Instr				),
		.O_Term(			O_Term					),
		.O_IssueNo(			O_IssueNo				),
		.O_Nack(			O_Nack					)
	);


	//// Buffers between FrontENd and Scalar Unit
	//	 Buffer for Instructions
	RingBuff #(
		.NUM_ENTRY(			SIZE_THREAD_MEM			),
		.TYPE(				instr_t					)
	) Instr_Buff
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We_Buff					),
		.I_Re(				Re_Buff					),
		.I_Data(			Buff_Instr				),
		.O_Data(			Instr					),
		.O_Full(			Buff_Full				),
		.O_Empty(			Buff_Empty				),
		.O_Num(										)
	);


	//	 Buffer for SIMT Thread-ID
	RingBuff #(
		.NUM_ENTRY(			SIZE_THREAD_MEM			),
		.TYPE(				id_t					)
	) ID_Buff
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				IDBuff_We				),
		.I_Re(				IDBuff_Re				),
		.I_Data(			Buff_ThreadID			),
		.O_Data(			ThreadID				),
		.O_Full(			IDBuff_Full				),
		.O_Empty(			IDBuff_Empty			),
		.O_Num(										)
	);


	Scalar_Unit Scalar_Unit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Empty(			Buff_Empty				),
		.I_Req_St(			IDBuff_Re				),
		.O_Ack_St(			Ack_St					),
		.I_Commit_Req_V(	Commit_Req_V			),
		.I_En(				I_En_Exe				),
		.I_ThreadID(		ThreadID				),
		.I_Instr(			Instr					),
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
		.O_Re_Buff(			Re_Buff					),
		.O_V_Command(		V_Command				),
		.I_V_State(			V_Status				),
		.O_Lane_En(			En_Lane					),
		.O_Commit_Grant(	Commit_Grant			),
		.O_Status(			S_Status				),
		.O_Term(			Term					)
	);


	Vector_Unit Vector_Unit (
		.clock(				clock					),
		.reset(				reset					),
		.I_Commit_Grant(	Commit_Grant			),
		.I_En_Lane(			En_Lane					),
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
		.O_Commmit_Req(		Commit_Req_V			),
		.O_Status(			V_Status				)
	);

endmodule