///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module MPU
	import pkg_mpu::*;
	import pkg_tpu::*;
	import pkg_tpu::instr_t;
(
	input							clock,
	input							reset,
	input							I_Req_IF,			//Request from External
	input	mpu_if_t				I_Data_IF,			//Data from External
	input							O_Req_IF,			//Request to External
	output	mpu_if_t				O_Data_IF,			//Data to External
	output							O_Req,				//Issue Request
	output	instr_t					O_Instr,			//Instruction Stream to TPU
	output	mpu_issue_no_t			O_IssueNo,			//Issue No
	input							I_Req_Commit,		//Request of Commit
	input	[WIDTH_NUM_ISSUE-1:0]	I_CommitNo,			//Commit No.
	output	tpu_row_clm_t			O_TPU_Req,			//Request to Execute
	output	tpu_row_clm_t			O_TPU_En_Exe,		//Enable to TPUs
	output							I_Ld_Req,			//Request from Data Memory
	input	data_t					I_Ld_Data,			//Data from Data Memory
	input							I_Ld_Rls,			//Path Release
	output							O_St_Req,			//Request Storing to Data Memory
	output	data_t					O_St_Data,			//Storing Data to Data Memory
	output							O_St_Rls,			//Path Release
	output							O_Wait,				//Wait Signal to Host trying the store
	output	mpu_stat_t				O_Status			//Status Info to Host System
);


	logic						Req_st;
	id_t						ThreadID_S_St;
	instr_t						Length_St;
	logic						Ack_St;
	logic						No_ThMem;
	logic						End_Send_Thread;
	logic						IF_State;

	t_address_t					Used_Size;
	logic						Req_Ld;
	t_address_t					Address_Ld;
	instr_t						Instr_Ld;

	logic						Req_HazardCheck;
	id_t						ID_HazardCheck;


	logic						Req_Commit;
	mpu_issue_no_t				Issued_No;
	logic						Req_Issue;
	id_t						ThreadID_S;
	mpu_issue_no_t				IssueNo;


	logic						Req_Lookup;
	id_t						ThreadID_S_Ld;
	logic						Ack_Lookup;
	lookup_t					ThreadInfo;

	logic						Dmem_I_Req;
	data_t						Dmem_I_Data;
	logic						Dmem_O_Req;
	data_t						Dmem_O_Data;

	logic						Req_St;
	logic						IF_Req_St;
	instr_t						IF_Instr;

	tpu_row_clm_t				En_TPU;


	assign O_TPU_Req			= |En_TPU;
	assign O_TPU_En_Exe			= En_TPU;

	assign No_ThMem				= Used_Size >= SIZE_THREAD_MEM;
	assign O_Status.io			= IF_State;


	IF_MPU IF_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_IF(			I_Req_IF				),
		.I_Data_IF(			I_Data_IF				),
		.O_Req_IF(			O_Req_IF				),
		.O_Data_IF(			O_Data_IF				),
		.I_Ack_Dispatch(	End_Send_Thread			),
		.I_Ack_MapMan(		Ack_St					),
		.I_Ack_ThMem(		Ack_St					),
		.I_No_ThMem(		No_ThMem				),
		.I_Commit(			Req_Commit				),
		.O_St_Instr(		IF_Req_St				),
		.O_Instr(			IF_Instr				),
		.I_Req(				Dmem_O_Req				),
		.I_Data(			Dmem_O_Data				),
		.O_Req(				Dmem_I_Req				),
		.O_Data(			Dmem_I_Data				),
		.O_En_TPU(			O_TPU_En_Exe			),
		.O_State(			IF_State				)
	);


	DataService_MPU DataService_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req(				Dmem_I_Req				),
		.I_Data(			Dmem_I_Data				),
		.O_Req(				Dmem_O_Req				),
		.O_Data(			Dmem_O_Data				),
		.I_Ld_Req(			I_Ld_Req				),
		.I_Ld_Grant(		),//ToDO
		.I_Ld_Data(			I_Ld_Data				),
		.I_Ld_Rls(			I_Ld_Rls				),
		.O_St_Req(			O_St_Req				),
		.I_St_Grant(		),//ToDo
		.O_St_Data(			O_St_Data				),
		.O_St_Rls(			O_St_Rls				)
	);


	ThrreadMem_MPU ThrreadMem_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			IF_Req_St				),
		.O_Req_St(			Req_St					),
		.O_ThreadID_St(		ThreadID_S_St			),
		.O_Length_St(		Length_St				),
		.I_Ack_St(			Ack_St					),
		.I_Instr_St(		IF_Instr				),
		.I_Used_Size(		Used_Size				),
		.I_Req_Ld(			Req_Ld					),
		.I_Adddress_Ld(		Address_Ld				),
		.O_Instr_Ld(		Instr_Ld				),
		.O_Req(				Req_HazardCheck			),
		.O_ThreadID(		ID_HazardCheck			),
		.O_Wait(			O_Status.imem_wait		)
	);


	HazardCheck_MPU HazardCheck_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_Commit(		Req_Commit				),
		.I_Issued_No(		Issued_No				),
		.I_Req(				Req_HazardCheck			),
		.I_ThreadID_S(		ID_HazardCheck			),
		.O_Req_Issue(		Req_Issue				),
		.O_ThreadID_S(		ThreadID_S				),
		.O_IssueNo(			IssueNo					)
	);


	Dispatch_MPU Dispatch_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_Issue(		Req_Issue				),
		.I_ThreadID(		ThreadID_S				),
		.O_Req_Lookup(		Req_Lookup				),
		.O_ThreadID(		ThreadID_S_Ld			),
		.I_Ack_LookUp(		Ack_Lookup				),
		.I_ThreadInfo(		ThreadInfo				),
		.O_Ld(				Req_Ld					),
		.O_Address(			Address_Ld				),
		.I_Instr(			Instr_Ld				),
		.O_Req(				O_Req					),
		.O_Instr(			O_Instr					),
		.O_IssueNo(			O_IssueNo				),
		.I_IssueNo(			IssueNo					),
		.O_Send_Thread(		O_Status.send_thread	),
		.O_End_Send(		End_Send_Thread			)
	);


	MapMan_MPU MapMan_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_St(			Req_St					),
		.I_ThreadID_St(		ThreadID_S_St			),
		.I_Length_St(		Length_St				),
		.O_Ack_St(			Ack_St					),
		.I_ThreadID_Ld(		ThreadID_S_Ld			),
		.O_Used_Size(		Used_Size				),
		.I_Req_Lookup(		Req_Lookup				),
		.O_Ack_Lookup(		Ack_Lookup				),
		.O_ThreadInfo(		ThreadInfo				),
		.O_Full(			O_Status.full_mapman	)
	);


	Commit_MPU Commit_MPU (
		.clock(				clock					),
		.reset(				reset					),
		.I_Req_Issue(		Req_Issue				),
		.I_Issue_No(		IssueNo					),
		.I_Req_Commit(		I_Req_Commit			),
		.I_CommitNo(		I_CommitNo				),
		.O_Req_Commit(		Req_Commit				),
		.O_Issue_No(		Issued_No				),
		.O_Full(			O_Status.full_commit	)
	);

endmodule