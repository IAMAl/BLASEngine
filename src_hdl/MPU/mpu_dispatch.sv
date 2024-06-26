module Dispatch
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_Issue,					//Request from Previous Stage
	input	id_t				I_ThreadID,						//Scalar Thread-ID from Hazard Check Unit
	output						O_Req_Lookup,					//Request to MapMan Unit
	output	id_t				O_ThreadID,						//Scalar Thread-ID to Commit Unit
	input						I_Ack,							//Ack from MapMan Unit
	input	lookup_t			I_ThreadInfo,					//Instr Memory Info from MapMan Unit
	output						O_Ld,							//Load Instruction
	output	st_address_t		O_Address,						//Loading Address
	input	instr_t				I_Instr,						//Loaded Instruction
	output	instr_t				O_Instr,						//Send Loaded Instructions to TPUs
	input	id_t				I_IssueNo,						//Issue No
	output						O_Send_Thread					//Status
);


	logic							Loading;
	logic							End_Load;

	fsm_dispatch_t					FSM_Dispatch;

	logic							Set_Address;
	st_address_t					Length;
	st_address_t					Base_Addr;

	st_address_t					R_Length;
	st_address_t					R_Address;

	id_t							R_ThreadID;
	id_t							R_IssueNo;



	assign Set_Address		= I_Ack;
	assign Loading			= FSM_Dispatch == FSM_DPC_SEND_INSTRS;

	assign End_Load			= R_Length == 0;

	assign O_Req_Lookup		= FSM_Dispatch == FSM_DPC_GETINFO;
	assign O_ThreadID		= R_ThreadID;

	assign O_Ld				= Loading;
	assign O_Address		= R_Address;

	assign O_Instr.valid	= R_LdD1;
	assign O_Instr.instr	= R_Instr;

	assign O_Send_Thread	= FSM_Dispatch	== FSM_DPC_SEND_INSTRS;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld			<= 1'b0;
			R_LdD1			<= 1'b0;
			R_Instr			<= 0;
		end
		else begin
			R_Ld			<= Loading;
			R_LdD1			<= ( FSM_Dispatch == FSM_DPC_SEND_THREADID ) |
								( FSM_Dispatch == FSM_DPC_SEND_ISSUENO ) |
								( FSM_Dispatch == FSM_DPC_SEND_ILENGTH ) |
								R_Ld;
			R_Instr			<= ( FSM_Dispatch == FSM_DPC_SEND_THREADID ) ?	R_ThreadID :
								( FSM_Dispatch == FSM_DPC_SEND_ISSUENO ) ?	R_IssueNo :
								( FSM_Dispatch == FSM_DPC_SEND_ILENGTH ) ?	R_PLength :
																			I_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID		<= 0;
			R_IssueNo		<= 0;
		end
		else if ( I_Req ) begin
			R_ThreadID		<= I_ThreadID;
			R_IssueNo		<= I_IssueNo;
		end
	end

	assign Length			= I_ThreadInfo.length;
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length		<= 0;
		end
		else if ( Loading ) begin
			R_Length		<= R_Length - 1'b1;
		end
		else if ( Set_Address ) begin
			R_Length		<= Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_PLength		<= 0;
		end
		else if ( Set_Address ) begin
			R_PLength		<= Length;
		end
	end

	assign Base_Addr		= I_ThreadInfo.address;
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Address		<= 0;
		end
		else if ( Loading ) begin
			R_Address		<= R_Address + 1'b1;
		end
		else if ( Set_Address ) begin
			R_Address		<= Base_Addr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Dispatch	<= FSM_DPC_INIT;
		end
		else case ( FSM_Dispatch )
			FSM_DPC_INIT: begin
				if ( I_Req ) begin
					FSM_Dispatch	<= FSM_DPC_GETINFO;
				end
				else begin
					FSM_Dispatch	<= FSM_DPC_INIT;
				end
			end
			FSM_DPC_GETINFO: begin
				if ( I_Ack ) begin
					FSM_Dispatch	<= FSM_DPC_SEND_THREADID;
				end
				else begin
					FSM_Dispatch	<= FSM_DPC_GETINFO;
				end
			end
			FSM_DPC_SEND_THREADID: begin
				FSM_Dispatch	<= FSM_DPC_SEND_ISSUENO;
			end
			FSM_DPC_SEND_ISSUENO: begin
				FSM_Dispatch	<= FSM_DPC_SEND_ILENGTH;
			end
			FSM_DPC_SEND_ILENGTH: begin
				FSM_Dispatch	<= FSM_DPC_SEND_INSTRS;
			end
			FSM_DPC_SEND_INSTRS: begin
				if ( End_Load ) begin
					FSM_Dispatch	<= FSM_DPC_INIT;
				end
				else begin
					FSM_Dispatch	<= FSM_DPC_SEND_INSTRS;
				end
			end
			default: begin
				FSM_Dispatch	<= FSM_DPC_INIT;
			end
		endcase
	end

endmodule