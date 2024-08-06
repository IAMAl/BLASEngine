///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	IF_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module IF_MPU
	import pkg_mpu::*;
(
	input							clock,
	input							reset,
	input							I_Req,
	input	mpu_if_t				I_Data,
	output							O_Ack,
	output	mpu_if_t				O_Data,
	input							I_Ack_Dispatch,
	input							I_Ack_MapMan,
	input							I_Ack_ThMem,
	input							I_Run,
	output	istr_t					O_Instr,
	output	data_t					O_Data,
	output							O_State
);

	mpu_fsm_if_t					R_FSM_IF_MPU;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
		end
		else case ( R_FSM_IF_MPU )
			FSM_INIT_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_COMMAND_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
			end
			FSM_COMMAND_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_CHK_CMD_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_COMMAND_IF_MPU;
				end
			end
			FSM_CHK_CMD_IF_MPU: begin
				if ( is_Stop ) begin
					R_FSM_IF_MPU	<= FSM_STOP_IF_MPU;
				end
				else if ( is_Run ) begin
					R_FSM_IF_MPU	<= FSM_RUN_CAPTURE_ID_IF_MPU;
				end
				else if ( is_Store_Prog ) begin
					R_FSM_IF_MPU	<= FSM_ST_CAPTURE_ID_IF_MPU;
				end
				else if ( is_Store_Data ) begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_ID_IF_MPU;
				end
				else if ( is_Load_Data ) begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_ID_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
			end
			FSM_STOP_IF_MPU: begin
				if ( is_Start ) begin
					R_FSM_IF_MPU	<= FSM_RUN_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_STOP_IF_MPU;
				end
			end
			FSM_RUN_CAPTURE_ID_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_RUN_QUERY_MAPMAN_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_RUN_CAPTURE_ID_IF_MPU;
				end
			end
			FSM_RUN_QUERY_MAPMAN_IF_MPU: begin
				if ( I_Ack_MapMan ) begin
					R_FSM_IF_MPU	<= FSM_RUN_QUERY_THMEM_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_RUN_QUERY_MAPMAN_IF_MPU;
				end
			end
			FSM_RUN_QUERY_THMEM_IF_MPU: begin
				if ( I_Ack_ThMem ) begin
					R_FSM_IF_MPU	<= FSM_RUN_DISPATCH_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_RUN_QUERY_THMEM_IF_MPU;
				end
			end
			FSM_RUN_DISPATCH_IF_MPU: begin
				if ( I_Ack_Dispatch ) begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_RUN_DISPATCH_IF_MPU;
				end
			end
			FSM_ST_CAPTURE_ID_IF_MPU: begin
				if ( I_Ack_ThMem ) begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_CAPTURE_ID_IF_MPU;
				end
			end
			FSM_ST_DATA_ID_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_STRIDE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_ID_IF_MPU;
				end
			end
			FSM_ST_DATA_STRIDE_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_BASE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_STRIDE_IF_MPU;
				end
			end
			FSM_ST_DATA_BASE_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_BASE_IF_MPU;
				end
			end
			FSM_ST_DATA_IF_MPU: begin
				if ( is_End_Store ) begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_IF_MPU;
				end
			end
			FSM_LD_DATA_ID_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_STRIDE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_ID_IF_MPU;
				end
			end
			FSM_LD_DATA_STRIDE_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_BASE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_STRIDE_IF_MPU;
				end
			end
			FSM_LD_DATA_BASE_IF_MPU: begin
				if ( I_Req ) begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_STRIDE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_BASE_IF_MPU;
				end
			end
			FSM_LD_DATA_IF_MPU: begin
				if ( is_End_Load ) begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_IF_MPU;
				end
			end
			default: begin
				R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
			end
		endcase
	end

endmodule