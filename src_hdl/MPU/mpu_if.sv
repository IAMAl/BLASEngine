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
	input							I_Req_IF,
	input	mpu_if_t				I_Data_IF,
	output	mpu_if_t				O_Data_IF,
	input							I_Ack_Dispatch,
	input							I_Ack_MapMan,
	input							I_Ack_ThMem,
	input							I_No_ThMem,
	input							I_Commit,
	output	instr_t					O_Instr,
	input							I_Ld_Data,
	input	data_t					I_Data,
	output							O_St_Data,
	output	data_t					O_Data,
	output	[3:0]					O_State
);


	logic							is_Run;
	logic							is_Stop;
	logic							is_Store_Prog;
	logic							is_Store_Data;
	logic							is_Load_Data;

	logic							is_End_Load;
	logic							is_End_Store;

	logic							Set_Ready;
	logic							Set_Run;
	logic							Set_NoThMem;

	logic							Clr_Ready;
	logic							Clr_Run;
	logic							Clr_NoThMem;

	logic							Ready;
	logic							Run;
	logic							NoThMem;

	mpu_fsm_if_t					R_FSM_IF_MPU;


	assign O_State			= { NoThMem, Stop, Run, Ready };

	assign O_St_Data		=	  ( R_FSM_IF_MPU  > FSM_ST_CAPTURE_ID_IF_MPU ) & ( R_FSM_IF_MPU <= FSM_ST_DATA_IF_MPU ) &	I_Data_IF.v;
	assign O_Data			= (   ( R_FSM_IF_MPU  > FSM_ST_CAPTURE_ID_IF_MPU ) & ( R_FSM_IF_MPU <= FSM_ST_DATA_IF_MPU ) ) ?	I_Data_IF.data : '0;

	assign O_St_Instr		=	  ( R_FSM_IF_MPU == FSM_ST_CAPTURE_ID_IF_MPU ) & I_Data_IF.v;
	assign O_Instr			= 	  ( R_FSM_IF_MPU == FSM_ST_CAPTURE_ID_IF_MPU ) ? I_Data_IF.data : '0;

	assign O_Data_IF.v		= 	  ( R_FSM_IF_MPU == FSM_LD_DATA_IF_MPU ) & I_Ld_Data;
	assign O_Data_IF.data	= 	( ( R_FSM_IF_MPU == FSM_LD_DATA_IF_MPU ) & I_Ld_Data ) ?	I_Data : '0;


	assign is_Run			= I_Req_IF & I_Data[0];
	assign is_Store_Prog	= I_Req_IF & I_Data[1];
	assign is_Store_Data	= I_Req_IF & I_Data[2];
	assign is_Load_Data		= I_Req_IF & I_Data[3];
	assign is_Stop			= I_Req_IF & I_Data[4];


	assign Set_Ready		= (   ( R_FSM_IF_MPU == FSM_RUN_QUERY_THMEM_IF_MPU ) & I_Ack_ThMem &  I_No_ThMem ) |
								( ( R_FSM_IF_MPU == FSM_ST_CAPTURE_ID_IF_MPU )   & I_Ack_ThMem & ~I_No_ThMem );
								( ( R_FSM_IF_MPU == FSM_LD_DATA_ID_IF_MPU )		 & is_End_Load ) |
								( ( R_FSM_IF_MPU == FSM_ST_DATA_IF_MPU )		 & is_End_Store );

	assign Clr_Ready		= (   ( R_FSM_IF_MPU == FSM_RUN_QUERY_THMEM_IF_MPU ) & I_Ack_ThMem & ~I_No_ThMem ) |
								(   R_FSM_IF_MPU == FSM_RUN_CAPTURE_ID_IF_MPU ) |
								( ( R_FSM_IF_MPU == FSM_LD_DATA_ID_IF_MPU ) ) |
								( ( R_FSM_IF_MPU == FSM_ST_CAPTURE_ID_IF_MPU ) );

	assign Set_Run			= (   ( R_FSM_IF_MPU == FSM_RUN_DISPATCH_IF_MPU )	 & I_Ack_Dispatch );
	assign Clr_Run			= I_Commit;

	assign Set_NoThMem		= (   ( R_FSM_IF_MPU == FSM_ST_CAPTURE_ID_IF_MPU )   & I_Ack_ThMem &  I_No_ThMem );
	assign Clr_NoThMem		= I_Req_IF;

	assign Stop				= (	  ( R_FSM_IF_MPU == FSM_STOP_IF_MPU ) );


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Ready		<= 1'b0;
		end
		else if ( Clr_Ready ) begin
			Ready		<= 1'b0;
		end
		else if ( Set_Ready ) begin
			Ready		<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Run		<= 1'b0;
		end
		else if ( Clr_Run ) begin
			Run			<= 1'b0;
		end
		else if ( Set_Run ) begin
			Run			<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			NoThMem		<= 1'b0;
		end
		else if ( Clr_NoThMem ) begin
			NoThMem		<= 1'b0;
		end
		else if ( Set_NoThMem ) begin
			NoThMem		<= 1'b1;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
		end
		else case ( R_FSM_IF_MPU )
			FSM_INIT_IF_MPU: begin
				if ( I_Req_IF ) begin
					R_FSM_IF_MPU	<= FSM_COMMAND_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
			end
			FSM_COMMAND_IF_MPU: begin
				if ( I_Req_IF ) begin
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
				if ( is_Run ) begin
					R_FSM_IF_MPU	<= FSM_RUN_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_STOP_IF_MPU;
				end
			end
			FSM_RUN_CAPTURE_ID_IF_MPU: begin
				if ( I_Req_IF ) begin
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
				if ( I_Ack_ThMem & ~I_No_ThMem ) begin
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
				if ( I_Ack_ThMem & ~I_No_ThMem ) begin
					R_FSM_IF_MPU	<= FSM_INIT_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_CAPTURE_ID_IF_MPU;
				end
			end
			FSM_ST_DATA_ID_IF_MPU: begin
				if ( I_Req_IF ) begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_STRIDE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_ID_IF_MPU;
				end
			end
			FSM_ST_DATA_STRIDE_IF_MPU: begin
				if ( I_Req_IF ) begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_BASE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_ST_DATA_STRIDE_IF_MPU;
				end
			end
			FSM_ST_DATA_BASE_IF_MPU: begin
				if ( I_Req_IF ) begin
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
				if ( I_Req_IF ) begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_STRIDE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_ID_IF_MPU;
				end
			end
			FSM_LD_DATA_STRIDE_IF_MPU: begin
				if ( I_Req_IF ) begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_BASE_IF_MPU;
				end
				else begin
					R_FSM_IF_MPU	<= FSM_LD_DATA_STRIDE_IF_MPU;
				end
			end
			FSM_LD_DATA_BASE_IF_MPU: begin
				if ( I_Req_IF ) begin
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