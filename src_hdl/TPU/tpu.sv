module tpu
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_En_Exe,
	input						I_Req,
	input	instr_t				I_Instr,
	output	s_address_t			O_S_Address,
	output	s_store_t			O_S_St,
	output	s_load_req_t		O_S_Ld_Req,
	input	s_load_t			I_S_Ld_Data,
	output	v_address_t			O_V_Address,
	output	v_store_t			O_V_St,
	output	v_load_req_t		O_V_Ld,
	input	v_load_t			I_V_Ld,
	output						O_Term,
	output						O_Nack
);

	instr_t						Buff_Instr;
	logic						Buff_We;
	logic						Buff_Re;
	logic 						Buff_Full;
	logic						Buff_Empty;
	instr_t						Instr;

	id_t						Buff_ThreadID_SIMT;
	logic						IDBuff_We;
	logic						IDBuff_Re;
	logic						IDBuff_Full;
	logic						IDBuff_Empty;
	id_t						ThreadID_SIMT;

	data_t						In_Scalar_Data;
	data_t						Out_Scalar_Data;

	s_stat_t					S_Status;
	command_t					V_Command;
	v_stat_t					V_Status;
	logic	{WIDTH_LANES-1:0}	Rotate_Amount1;
	logic	{WIDTH_LANES-1:0}	Rotate_Amount2;


	FrontEnd FrontEnd (
		.clock(					clock					),
		.reset(					reset					),
		.I_En_Exe(				I_En_Exe				),
		.I_Req(					I_Req					),
		.I_Full(				Buff_Full				),
		.I_Term(				),
		.I_Nack(				),
		.I_Instr(				I_Instr					),
		.O_We(					Buff_We					),
		.O_IssueNo(				IssueNo					),
		.O_ThreadID_SIMT(		Buff_ThreadID_SIMT		),
		.O_Instr(				Buff_Instr				),
		.O_Term(				O_Term					),
		.O_Nack(				O_Nack					)
	);


	buff #(
		.NUM_ENTRY(				)
	) instr_buff
	(
		.clock(					clock					),
		.reset(					reset					),
		.I_We(					Buff_We					),
		.I_Re(					Buff_Re					),
		.I_Data(				Buff_Instr				),
		.O_Data(				Instr					),
		.O_Full(				Buff_Full				),
		.O_Empty(				Buff_Empty				)
	);


	buff #(
		.NUM_ENTRY(				)
	) id_buff
	(
		.clock(					clock					),
		.reset(					reset					),
		.I_We(					IDBuff_We				),
		.I_Re(					IDBuff_Re				),
		.I_Data(				Buff_ThreadID_SIMT		),
		.O_Data(				ThreadID_SIMT			),
		.O_Full(				IDBuff_Full				),
		.O_Empty(				IDBuff_Empty			)
	);


	scalar_unit scalar_unit (
		.clock(					clock					),
		.reset(					reset					),
		.I_Empty(				Buff_Empty				),
		.I_Instr(				Instr					),
		.I_En(					),
		.I_IssueNo(				IssueNo					),
		.I_ThreadID_SIMT(		ThreadID_SIMT			),
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
		.O_Re(					Buff_Re					),
		.O_V_Command(			V_Command				),
		.O_Rotate_Amount1(		Rotate_Amount1			),
		.O_Rotate_Amount2(		Rotate_Amount2			),
		.O_Status(				S_Status				)
	);


	vector_unit vector_unit (
		.clock(					clock					),
		.reset(					reset					),
		.I_Command(				V_Command				),
		.I_Rotate_Amount1(		Rotate_Amount1			),
		.I_Rotate_Amount2(		Rotate_Amount2			),
		.I_Scalar_Data(			Out_Scalar_Data			),
		.O_Scalar_Data(			In_Scalar_Data			),
		.O_Address(				O_V_Address				),
		.O_St(					O_V_St					),
		.O_Ld(					O_V_Ld					),
		.I_Ld(					I_V_Ld					),
		.O_Status(				V_Status				)
	);

endmodule