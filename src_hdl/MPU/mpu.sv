module mpu
	import pkg_mpu::*;
	import pkg_tpu::*;
(
	input							clock,
	input							reset,
	input							I_Req_St,			//Request to Store Thread Program
	input	instr_t					I_Instr,			//Thread Program Port
	output	instr_t					O_Instr,			//Send Thread Program to TPUs
	input							I_Req_Commit,		//Request of Commit
	input	[WIDTH_ENTRY_STH-1:0]	I_CommitNo,			//Commit No.
	output							O_Wait,				//Wait Signal to Host trying the store
	output	mpu_stat_t				O_Status			//Status Info to Host System
);


	logic						Req_st;
	id_t						ThreadID_S_St;
	instr_t						Length_St;
	logic						Ack_St;

	t_address_t					Used_Size;
	logic						Req_Ld;
	t_address_t					Address_Ld;
	instr_t						Instr_Ld;

	logic						Req_HazardCheck;
	id_t						ID_HazardCheck;


	logic						Req_Commit;
	issue_no_t					Issued_No;
	logic						Req_HazardCheck;
	logic						Req_Issue;
	id_t						ThreadID_S;
	issue_no_t					IssueNo;


	logic						Req_Lookup;
	id_t						ThreadID_S_Ld;
	logic						Ack_Lookup;
	lookup_t					ThreadInfo;


	ThreadMem ThreadMem (
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
		.O_Req(					Req_HazardCheck			),
		.O_ThreadID(			ID_HazardCheck			),
		.O_Wait(				O_Status.imem_wait		)
	);


	HazardCheck_MPU HazardCheck_MPU (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_Commit(			Req_Commit				),
		.I_Issued_No(			Issued_No				),
		.I_Req(					Req_HazardCheck			),
		.I_ThreadID_S(			ID_HazardCheck			),
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
		.I_IssueNo(				IssueNo					),
		.O_Send_Thread(			O_Status.send_thread	)
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
		.O_Full(				O_Status.full_mapman	)
	);


	Commit Commit (
		.clock(					clock					),
		.reset(					reset					),
		.I_Req_Issue(			Req_Issue				),
		.I_Issue_No(			IssueNo					),
		.I_Req_Commit(			I_Req_Commit			),
		.I_CommitNo(			I_CommitNo				),
		.O_Req_Commit(			Req_Commit				),
		.O_Issue_No(			Issued_No				),
		.O_Full(				O_Status.full_commit	)
	);

endmodule