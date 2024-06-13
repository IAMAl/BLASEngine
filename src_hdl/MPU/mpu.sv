module mpu (
	input							clock,
	input							reset,
	input							I_Req_St,			//Request to Store Thread Program
	input	instr_t					I_Instr,			//Thread Program Port
	output	instr_t					O_Instr,			//Send Thread Program to TPUs
	input							I_Req_Commit,		//Request of Commit
	input	[WIDTH_ENTRY_STH-1:0]	I_CommitNo,			//Commit No.
	output							O_Wait,				//Wait Signal to Host tring the store
	output	tpu_stat_t				O_Status
);


	InstrMem InstrMem (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_St(				I_Req_St				),
		.O_Req_St(				Req_St					),
		.O_ThreadID_St(			ThreadID_S_St			),
		.O_Length_St(			Length_St				),
		.I_Ack_St(				Ack_St					),
		.I_Instr_St(			I_Instr					),
		.I_Used_Size(			Used_Size				),
		.I_Req_Ld(				Req_Ld					),
		.I_Adddress_Ld(			Address_Ld				),
		.O_Instr_Ld(			Instr_Ld				),
		.O_Wait(				O_Wait					)
	);


	HazardCheck HazardCheck (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_Commit(			Req_Commit				),
		.I_CommitNo(			CommitNo				),
		.I_Req(					),
		.I_ThreadID_S(			),
		.O_Req_Issue(			Req_Issue				),
		.O_ThreadID_S(			ThreadID_S				),
		.O_IssueNo(				IssueNo					),
	);


	Dispatch Dispatch (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_Issue(			Req_Issue				),
		.I_ThreadID(			ThreadID_S				),
		.O_Req_Lookup(			Req_Lookup				),
		.O_ThreadID(			ThreadID_S_Ld			),
		.I_Ack_LookUp(			Ack_Lookup				),
		.I_ThreadInfo(			ThreadInfo				),
		.O_Ld(					Req_Ld					),
		.O_Address(				Address_Ld				),
		.I_Instr(				Instr_Ld				),
		.O_Instr(				O_Instr					),
		.O_Status(				)
	);


	MapMan MapMan (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_St(				Req_St					),
		.I_ThreadID_St(			ThreadID_S_St			),
		.I_Length_St(			Length_St				),
		.O_Ack_St(				Ack_St					),
		.I_ThreadID_Ld(			ThreadID_S_Ld			),
		.O_Used_Size(			Used_Size				),
		.I_Req_Lookup(			Req_Lookup				),
		.O_Ack_Lookup(			Ack_Lookup				),
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