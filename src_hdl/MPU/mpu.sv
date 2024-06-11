module mpu (
	input						clock,
	input						reset,
	input						I_Req_St,
	output						O_Req_St,
	input	instr_t				I_Instr,
	output	instr_t				O_Instr,
	output						O_Wait,
	output	tpu_stat_t			O_Status
);


	InstrMem InstrMem (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_St(				I_Req_St				),
		.O_Req_St(				O_Req_St				),
		.O_ThreadID_St(			ThreadID_Scalar			),
		.O_Length_St(			St_Length				),
		.I_Ack_St(				St_Ack					),
		.I_Instr_St(			I_Instr					),
		.I_Used_Size(			),
		.I_Req_Ld(				Ld_Req					),
		.I_Adddress_Ld(			Ld_Address				),
		.O_Instr_Ld(			Ld_Instr				),
		.O_Wait(				O_Wait					)
	);


	HazardCheck HazardCheck (
		.clock(					clock					),
		.reset(					reset					),
		.I_Ack(					Hazard_Ack	),////
		.I_Commit(				Req_Commit				),
		.I_CommitNo(			CommitNo				),
		.I_Req(					),
		.I_ThreadID_S(			ThreadID_Scalar			),
		.O_Req(					Hazard_Req				),
		.O_ThreadID_S(			ThreadID_S				),
		.O_IssueNo(				IssueNo					),
	);


	Dispatch Dispatch (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req(					),
		.I_ThreadID(			ThreadID_S				),
		.O_Req_Lookup(			Hazard_Req				),
		.O_ThreadID(			Ld_ThreadID				),
		.I_Ack(					Ld_Ack					),
		.I_ThreadInfo(			ThreadInfo				),
		.O_Ld(					Ld_Req					),
		.O_Address(				Ld_Address				),
		.I_Instr(				Ld_Instr				),
		.O_Instr(				O_Instr					),
		.O_Status(				)
	);


	MapMan MapMan (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_St(				St_Req					),
		.I_ThreadID_St(			ThreadID_Scalar			),
		.I_Length_St(			St_Length				),
		.O_Ack_St(				St_Ack					),
		.I_ThreadID_Ld(			Ld_ThreadID				),
		.O_Address_St(			),////Unnecessary?
		.I_Req_Ld(				Ld_Req					),
		.O_Ack_Ld(				Ld_Ack					),
		.O_ThreadInfo(			ThreadInfo				),
		.O_Full(				)
	);


	Commit Commit (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_Issue(			Hazard_Req				),
		.I_Issue_No(			IssueNo					),
		.I_Req_Commit(			I_Req_Commit			),
		.I_CommitNo(			I_CommitNo				),
		.O_Req_Commit(			Req_Commit				),
		.O_CommitNo(			CommitNo				)
	);

endmodule