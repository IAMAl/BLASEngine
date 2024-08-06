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
	output	s_address_t			O_S_Address,			//Addresses for Scalar Lane Data Memory
	output	s_store_t			O_S_St,					//Store Request for Scalar Lane Data Memory
	output	s_load_req_t		O_S_Ld_Req,				//Load Request to Scalar Lane Data Memory
	input	s_load_t			I_S_Ld_Data,			//Loaded Data from Scalar Lane Data Memory
	output	v_address_t			O_V_Address,			//Addresses for Vector Lane Data Memories
	output	v_store_t			O_V_St,					//Store Requests for Vector Lane Data Memories
	output	v_load_req_t		O_V_Ld,					//Load Requests to Vector Lane Data Memories
	input	v_load_t			I_V_Ld,					//Loaded Data from Vector Lane Data Memories
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
		.O_Address1(			O_S_Address[0]			),
		.O_Address2(			O_S_Address[1]			),
		.O_Ld_Req1(				O_S_Ld_Req[0]			),
		.O_Ld_Req2(				O_S_Ld_Req[1]			),
		.I_Ld_Data1(			I_S_Ld_Data[0]			),
		.I_Ld_Data2(			I_S_Ld_Data[1]			),
		.O_St_Req1(				O_S_St[0].Req			),
		.O_St_Req2(				O_S_St[1].Req			),
		.O_St_Data1(			O_S_St[0].Data			),
		.O_St_Data2(			O_S_St[1].Data			),
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
		.I_ThreadID(			),//ToDo
		.I_Command(				V_Command				),
		.I_Scalar_Data(			Out_Scalar_Data			),
		.O_Scalar_Data(			In_Scalar_Data			),
		.I_Ack_Ld(				),//ToDo
		.O_Address(				O_V_Address				),
		.O_St(					O_V_St					),
		.O_Ld(					O_V_Ld					),
		.I_Ld(					I_V_Ld					),
		.O_Commmit_Req(			Commmit_Req_V			),
		.O_Status(				V_Status				)
	);

endmodule