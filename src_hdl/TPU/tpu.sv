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
(
	input						clock,
	input						reset,
	input						I_En_Exe,				//Enable Executing
	input						I_Req,					//Request from MPU
	input	instr_t				I_Instr,				//Instructions from MPU
	output	s_ldst_t			O_S_LdSt,				//Load/Store Command
	input	s_ld_data			I_S_Ld_Data,			//Loaded Data from DMem
	output	s_ld_data			O_S_St_Data,			//Storing Data to Dmem
	input	[1:0]				I_S_Ld_Ready,			//Flag: Ready
	input	[1:0]				I_S_Ld_Grant,			//Flag: Grant for Request
	input	[1:0]				I_S_St_Ready,			//Flag: Ready
	input	[1:0]				I_S_St_Grant,			//Flag: Grant
	input	v_ldst_t			O_V_LdSt,				//Load/Store Command
	input	v_ld_data			I_V_Ld_Data,			//Loaded Data
	output	v_ld_data			O_V_St_Data,			//Storing Data
	input	v_ready_t			I_V_Ld_Ready,			//Flag:	Ready
	input	v_grant_t			I_V_Ld_Grant,			//Flag: Grant
	input	v_ready_t			I_V_St_Ready,			//Flag: Ready
	input	v_grant_t			I_V_St_Grant,			//Flag: Grant
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

	s_stat_t					S_Status;

	command_t					V_Command;
	lane_t						En_Lane;
	lane_t						V_Status;

	logic						Commmit_Req_V;


	//// Service Management UNit
	FrontEnd FrontEnd (
		.clock(					clock					),
		.reset(					reset					),
		.I_En_Exe(				I_En_Exe				),
		.I_Req(					I_Req					),
		.I_Full(				Buff_Full				),
		.I_Term(				),//ToDo
		.I_Nack(				~Ack_St					),
		.I_Instr(				I_Instr					),
		.O_We(					We_Buff					),
		.O_IssueNo(				IssueNo					),
		.O_ThreadID(			Buff_ThreadID			),
		.O_Instr(				Buff_Instr				),
		.O_Term(				O_Term					),
		.O_Nack(				O_Nack					)
	);


	//// Buffers between FrontENd and Scalar Unit
	//	 Buffer for Instructions
	buff #(
		.NUM_ENTRY(				SIZE_THREAD_MEM			),
		.TYPE_DEF(				instr_t					)
	) Instr_Buff
	(
		.clock(					clock					),
		.reset(					reset					),
		.I_We(					We_Buff					),
		.I_Re(					Re_Buff					),
		.I_Data(				Buff_Instr				),
		.O_Data(				Instr					),
		.O_Full(				Buff_Full				),
		.O_Empty(				Buff_Empty				)
	);

	//	 Buffer for SIMT Thread-ID
	buff #(
		.NUM_ENTRY(				SIZE_THREAD_MEM			),
		.TYPE_DEF(				id_t					)
	) ID_Buff
	(
		.clock(					clock					),
		.reset(					reset					),
		.I_We(					IDBuff_We				),
		.I_Re(					IDBuff_Re				),
		.I_Data(				Buff_ThreadID			),
		.O_Data(				ThreadID				),
		.O_Full(				IDBuff_Full				),
		.O_Empty(				IDBuff_Empty			)
	);


	Scalar_Unit Scalar_Unit (
		.clock(					clock					),
		.reset(					reset					),
		.I_Empty(				Buff_Empty				),
		.I_Req_St(				IDBuff_Re				),
		.O_Ack_St(				Ack_St					),
		.I_Instr(				Instr					),
		.I_En(					I_En_Exe				),
		.I_IssueNo(				IssueNo					),
		.I_ThreadID(			ThreadID				),
		.I_Commmit_Req_V(		Commmit_Req_V			),
		.I_Scalar_Data(			In_Scalar_Data			),
		.O_Scalar_Data(			Out_Scalar_Data			),
		.O_LdSt(				O_S_LdSt				),
		.I_Ld_Data(				I_S_Ld_Data				),
		.O_St_Data(				O_S_St_Data				),
		.I_Ld_Ready(			I_S_Ld_Ready			),
		.I_Ld_Grant(			I_S_Ld_Grant			),
		.I_St_Ready(			I_S_St_Ready			),
		.I_St_Grant(			I_S_St_Grant			),
		.O_Re_Buff(				Re_Buff					),
		.O_V_Command(			V_Command				),
		.I_V_State(				V_Status				),
		.O_Lane_En(				En_Lane					),
		.O_Status(				S_Status				)
	);


	Vector_Unit Vector_Unit (
		.clock(					clock					),
		.reset(					reset					),
		.I_En_Lane(				En_Lane					),
		.I_ThreadID(			ThreadID				),
		.I_Command(				V_Command				),
		.I_Scalar_Data(			Out_Scalar_Data			),
		.O_Scalar_Data(			In_Scalar_Data			),
		.O_LdSt(				O_V_LdSt				),
		.I_Ld_Data(				I_V_Ld_Data				),
		.O_St_Data(				O_V_St_Data				),
		.I_Ld_Ready(			I_V_Ld_Ready			),
		.I_Ld_Grant(			I_V_Ld_Grant			),
		.I_St_Ready(			I_V_St_Ready			),
		.I_St_Grant(			I_V_St_Grant			),
		.O_Commmit_Req(			Commmit_Req_V			),
		.O_Status(				V_Status				)
	);

endmodule