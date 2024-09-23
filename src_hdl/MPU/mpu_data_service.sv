///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	DataService_MPU
///////////////////////////////////////////////////////////////////////////////////////////////////

module DataService_MPU
import pkg_tpu::*;
import pkg_mpu::*;
import pkg_mpu::fsm_extern_st;
import pkg_mpu::fsm_extern_ld;
#(
	parameter int	BUFF_SIZE	= 128
)(
	input						clock,
	input						reset,
	input						I_Req,					//Request from Extern
	input	data_t				I_Data,					//Data from Extern
	output						O_Req,					//Request to Extern
	output	data_t				O_Data,					//Data to Extern
	input						I_Ld_Req,				//Request from Data Memory
	input						I_Ld_Grant,				//Grant for Request
	input	data_t				I_Ld_Data,				//Data from Data Memory
	input						I_Ld_Rls,				//End of Loading
	output						O_St_Req,				//Request Storing to Data Memory
	input						I_St_Grant,				//Grant for Request
	output	data_t				O_St_Data,				//Storing Data to Data Memory
	output						O_St_Rls				//End of Storing
);


	//ToDo
	localparam int NOTIFY_DATA	= -1;

	localparam int WIDTH_BUFF	= $clog2(BUFF_SIZE);


	logic						is_FSM_Extern_Not_Init;
	logic						is_FSM_Extern_Recv_Stride;
	logic						is_FSM_Extern_Run;
	logic						is_FSM_Extern_St_Buff;
	logic						is_FSM_Extern_St_Notify;
	logic						is_FSM_Extern_St_Run;
	logic						is_FSM_Extern_Ld_Run;

	logic						Half_Data_Block_Stored;
	logic						Half_Buffer_Stored;

	logic						Ld_Req;
	logic						St_Req;

	logic						Store_Buff_Ld;
	logic						Store_Buff_St;

	logic						Load_Buff_Ld;
	logic						Load_Buff_St;

	logic						We;
	logic						Re;
	logic	[WIDTH_BUFF-1:0]	Wr_Ptr;
	logic	[WIDTH_BUFF-1:0]	Rd_Ptr;
	logic						Empty;
	logic						Full;
	logic	[WIDTH_BUFF:0]		Num_Stored;

	data_t						Buff_In_Data;

	logic						Store_Length;

	logic						Run_St_Service;
	logic						Run_Ld_Service;

	logic						is_Ld_Notified;


	data_t						R_Length;
	logic						R_Ld_Req;
	logic						R_St_Req;

	logic	[WIDTH_BUFF-1:0]	Counter_St;

	fsm_extern_serv				FSM_Extern_Serv;
	fsm_extern_st				FSM_Extern_St;
	fsm_extern_ld				FSM_Extern_Ld;

	data_t						Buff_Data	[BUFF_SIZE-1:0];


	//
	assign is_FSM_Extern_Not_Init	= FSM_Extern_Serv != FSM_EXTERN_MPU_RECV_INIT;
	assign is_FSM_Extern_Run		= FSM_Extern_Serv == FSM_EXTERN_MPU_RECV_RUN;

	assign is_FSM_Extern_St_Buff	= FSM_Extern_St == FSM_EXTERN_MPU_ST_BUFF;
	assign is_FSM_Extern_St_Notify	= FSM_Extern_St == FSM_EXTERN_MPU_ST_NOTIFY;
	assign is_FSM_Extern_St_Run		= FSM_Extern_St == FSM_EXTERN_MPU_ST_RUN;
	assign is_FSM_Extern_Ld_Run		= FSM_Extern_Ld == FSM_EXTERN_MPU_LD_RUN;

	assign Half_Data_Block_Stored	= Counter_St == { 1'b0, ( ( R_Length + 1 ) >> 1 ) };
	assign Half_Buffer_Stored		= Counter_St == ( Num_Stored >> 1 );


	assign Ld_Req				= is_FSM_Extern_Recv_Stride &  I_Data[WIDTH_DATA-1];
	assign St_Req				= is_FSM_Extern_Recv_Stride & ~I_Data[WIDTH_DATA-1];

	// Storing to Buffer
	assign Store_Buff_St		= I_Req & is_FSM_Extern_Run & ( is_FSM_Extern_St_Buff | is_FSM_Extern_St_Notify | is_FSM_Extern_St_Run );
	assign Store_Buff_Ld		= is_FSM_Extern_Run & is_FSM_Extern_Ld_Run;

	// Loading from Buffer
	assign Load_Buff_St			= is_FSM_Extern_Run & is_FSM_Extern_St_Run;
	assign Load_Buff_Ld			= is_FSM_Extern_Run & is_FSM_Extern_Ld_Run;

	assign We					= Store_Buff_St | Store_Buff_Ld;
	assign Re					= Load_Buff_St | Load_Buff_Ld;

	assign Buff_In_Data			= ( Store_Buff_St ) ?	I_Data :
									( Store_Buff_Ld ) ?	I_Ld_Data :
														0;

	assign Store_Length			= I_Req & ( FSM_Extern_Serv == FSM_EXTERN_MPU_RECV_LENGTH );
	assign Run_St_Service		= St_Req & is_FSM_Extern_Run;
	assign Run_Ld_Service		= Ld_Req & is_FSM_Extern_Run;
	assign is_Ld_Notified		= ( I_Ld_Data == NOTIFY_DATA ) & is_FSM_Extern_Ld_Run;

	// IF
	assign O_Req				= Load_Buff_St & ~Empty;
	assign O_Data				= ( Load_Buff_St & ~Empty ) ?	Buff_Data[ Rd_Ptr ] : 0;

	// TPU (Router)
	assign O_St_Req				= Load_Buff_Ld | is_FSM_Extern_St_Notify;
	assign O_St_Data			= ( Load_Buff_Ld ) ?				I_Data :
									( is_FSM_Extern_St_Notify ) ?	NOTIFY_DATA :
																	0;
	assign O_St_Rls				= Counter_St == R_Length;


	// Capture Access-Length
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length		<= 0;
		end
		else if ( Store_Length ) begin
			R_Length		<= I_Data;
		end
	end


	// Service Flag
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Req		<= 1'b0;
		end
		else if ( I_Ld_Rls ) begin
			R_St_Req		<= 1'b0;
		end
		else if ( St_Req ) begin
			R_St_Req		<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Req		<= 1'b0;
		end
		else if ( I_Ld_Rls ) begin
			R_Ld_Req		<= 1'b0;
		end
		else if ( Ld_Req ) begin
			R_Ld_Req		<= 1'b1;
		end
	end


	//Counter
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Counter_St		<= 0;
		end
		else if ( O_St_Rls ) begin
			Counter_St		<= 0;
		end
		else if ( I_Req & is_FSM_Extern_St_Run ) begin
			Counter_St		<= Counter_St + 1'b1;
		end
	end


	// Buffer
	always_ff @( posedge clock ) begin
		if ( We ) begin
			Buff_Data[ Wr_Ptr ]	<= Buff_In_Data;
		end
	end


	// Service Handler
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_INIT;
		end
		else case ( FSM_Extern_Serv )
			FSM_EXTERN_MPU_RECV_INIT: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_STRIDE;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_INIT;
				end
			end
			FSM_EXTERN_MPU_RECV_STRIDE: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_LENGTH;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_STRIDE;
				end
			end
			FSM_EXTERN_MPU_RECV_LENGTH: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_BASE;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_LENGTH;
				end
			end
			FSM_EXTERN_MPU_RECV_BASE: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_RUN;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_BASE;
				end
			end
			FSM_EXTERN_MPU_RECV_RUN: begin
				if ( I_Ld_Rls | O_St_Rls ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_INIT;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_RUN;
				end
			end
			default: begin
				FSM_Extern_Serv	<= FSM_EXTERN_MPU_RECV_INIT;
			end
		endcase
	end


	//Store Control for Loaded Data from Data Memory
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Extern_St	<= FSM_EXTERN_MPU_ST_INIT;
		end
		else case ( FSM_Extern_St )
			FSM_EXTERN_MPU_ST_INIT: begin
				if ( Run_St_Service ) begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_BUFF;
				end
				else begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_INIT;
				end
			end
			FSM_EXTERN_MPU_ST_BUFF: begin
				if ( I_St_Grant ) begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_RUN;
				end
				else if ( Half_Buffer_Stored ) begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_NOTIFY;
				end
				else begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_BUFF;
				end
			end
			FSM_EXTERN_MPU_ST_NOTIFY: begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_BUFF;
			end
			FSM_EXTERN_MPU_ST_RUN: begin
				if ( O_St_Rls ) begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_INIT;
				end
				else begin
					FSM_Extern_St	<= FSM_EXTERN_MPU_ST_RUN;
				end
			end
			default: begin
				FSM_Extern_St	<= FSM_EXTERN_MPU_ST_INIT;
			end
		endcase
	end


	//Load Control fro Storing in Data Memory
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_INIT;
		end
		else case ( FSM_Extern_Ld )
			FSM_EXTERN_MPU_LD_INIT: begin
				if ( Run_Ld_Service ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_WAIT;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_INIT;
				end
			end
			FSM_EXTERN_MPU_LD_WAIT: begin
				if ( I_Ld_Grant ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_RUN;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_WAIT;
				end
			end
			FSM_EXTERN_MPU_LD_NOTIFY: begin
				if ( is_Ld_Notified ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_RUN;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_NOTIFY;
				end
			end
			FSM_EXTERN_MPU_LD_RUN: begin
				if ( is_Ld_Notified ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_NOTIFY;
				end
				else if ( I_Ld_Rls ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_INIT;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_RUN;
				end
			end
			default: begin
				FSM_Extern_Ld	<= FSM_EXTERN_MPU_LD_INIT;
			end
		endcase
	end


	//Store Buffer
	RingBuffCTRL_Re #(
		.NUM_ENTRY(			BUFF_SIZE				)
	) RingBuffCTRL
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.O_WAddr(			Wr_Ptr					),
		.O_RAddr(			Rd_Ptr					),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(				Num_Stored				)
	);

endmodule