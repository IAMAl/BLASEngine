///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	BLASEngine
//	Copyright (C) 2024  Shigeyuki TAKANO
//
//  GNU AFFERO GENERAL PUBLIC LICENSE
//	version 3.0
//
//	Module Name:	extern_handle
///////////////////////////////////////////////////////////////////////////////////////////////////

module extern_handle
	import pkg_tpu::*;
#(
	parameter int	BUFF_SIZE	= 128
)(
	input						clock,
	input						reset,
	input						I_Req,					//Request from Extern
	input	data_t				I_Data,					//Data from Extern
	input						I_Rls,					//Release Token from Extern
	output						O_Req,					//Request to Extern
	output	data_t				O_Data,					//Data to Extern
	output						O_Rls,					//Release TOken to Extern
	output						O_Ld_Req,				//Request Loading
	output	address_t			O_Ld_Length,			//Access-Length for Loading
	output	stride_t			O_Ld_Stride,			//Access-Stride for Loading
	output	address_t			O_Ld_Base,				//Access-Base Address for Loading
	input						I_Ld_Grant,				//Grant fro Load-Request
	input	data_t				I_Ld_Data,				//Loaded Data
	input						I_Ld_Term,				//End of Loading
	output						O_St_Req,				//Request Storing
	output	address_t			O_St_Length,			//Access-Length for Storing
	output	stride_t			O_St_Stride,			//Access-Stride for Storing
	output	address_t			O_St_Base,				//Access-Base Address for Storing
	input						I_St_Grant,				//Grant fro Store-Request
	output	data_t				O_St_Data,				//Storing Data
	input						I_St_Term				//End of Storing
);


	//ToDo
	localparam int NOTIFY_DATA		= -1;

	localparam int	WIDTH_BUFF		= $clog2(BUFF_SIZE);

	localparam int	HALF_BUFF_SIZE	= (BUFF_SIZE+1) / 2;
	localparam int	WIDTH_HALF_BUFF	= $clog2(HALF_BUFF_SIZE);


	logic						is_FSM_Extern_Run;
	logic						is_FSM_Extern_Recv_Stride;
	logic						is_FSM_Extern_Recv_Length;
	logic						is_FSM_Extern_Recv_Base;

	logic						is_FSM_Extern_St_Buff;
	logic						is_FSM_Extern_St_Notify;
	logic						is_FSM_Extern_St_Run;
	logic						is_FSM_Extern_Ld_Run;


	logic						Half_Data_Block_Stored;
	logic						Half_Buffer_Stored;

	logic						St_Req;
	logic						Ld_Req;

	logic						Store_Stride;
	logic						Store_Length;
	logic						Store_Base;

	logic						Store_Buff_St;
	logic						Store_Buff_Ld;

	logic						Load_Buff_St;
	logic						Load_Buff_Ld;

	logic						Output_St_Config;
	logic						Output_Ld_Config;


	data_t						Buff_In_Data;
	data_t						Buff_Data					[BUFF_SIZE-1:0];


	logic						Run_St_Service;
	logic						Run_Ld_Service;


	logic						is_Ld_Notified;


	address_t					R_Length;
	stride_t					R_Stride;
	address_t					R_Base;

	address_t					Counter_St;


	fsm_extern_t				FSM_Extern_Serv;
	fsm_extern_st_t				FSM_Extern_St;
	fsm_extern_ld_t				FSM_Extern_Ld;

	// Store Buffer
	logic						We;
	logic						Re;
	logic	[WIDTH_BUFF-1:0]	Wr_Ptr;
	logic	[WIDTH_BUFF-1:0]	Rd_Ptr;
	logic						Full;
	logic						Empty;
	logic	[WIDTH_BUFF:0]		Num_Stored;


	assign is_FSM_Extern_Run		= FSM_Extern_Serv == FSM_EXTERN_RUN;
	assign is_FSM_Extern_Recv_Stride= FSM_Extern_Serv == FSM_EXTERN_RECV_STRIDE;
	assign is_FSM_Extern_Recv_Length= FSM_Extern_Serv == FSM_EXTERN_RECV_LENGTH;
	assign is_FSM_Extern_Recv_Base	= FSM_Extern_Serv == FSM_EXTERN_RECV_BASE;

	assign is_FSM_Extern_St_Buff	= FSM_Extern_St == FSM_EXTERN_ST_BUFF;
	assign is_FSM_Extern_St_Notify	= FSM_Extern_St == FSM_EXTERN_ST_NOTIFY;
	assign is_FSM_Extern_St_Run		= FSM_Extern_St == FSM_EXTERN_ST_RUN;

	assign is_FSM_Extern_Ld_Run		= FSM_Extern_Ld == FSM_EXTERN_LD_RUN;

	assign Run_St_Service		= St_Req & is_FSM_Extern_Run;
	assign Run_Ld_Service		= Ld_Req & is_FSM_Extern_Run;

	assign is_Ld_Notified		= ( I_Ld_Data == NOTIFY_DATA ) & is_FSM_Extern_Ld_Run;

	assign Output_St_Config		= St_Req & ( FSM_Extern_Serv == FSM_EXTERN_RECV_SET );
	assign Output_Ld_Config		= Ld_Req & ( FSM_Extern_Serv == FSM_EXTERN_RECV_SET );

	assign Half_Data_Block_Stored	= Counter_St == { 1'b0, ( ( R_Length + 1 ) >> 1 ) };
	assign Half_Buffer_Stored		= Counter_St == ( Num_Stored >> 1 );

	// Load/Store Request Detection
	assign Ld_Req				= is_FSM_Extern_Recv_Stride &  I_Data[WIDTH_DATA-1];
	assign St_Req				= is_FSM_Extern_Recv_Stride & ~I_Data[WIDTH_DATA-1];

	// Set Access-Config
	assign Store_Stride			= is_FSM_Extern_Recv_Stride;
	assign Store_Length			= is_FSM_Extern_Recv_Length;
	assign Store_Base			= is_FSM_Extern_Recv_Base;

	// Storing to Buffer
	assign Store_Buff_St		= I_Req & is_FSM_Extern_Run & ( is_FSM_Extern_St_Buff | is_FSM_Extern_St_Notify | is_FSM_Extern_St_Run );
	assign Store_Buff_Ld		= is_FSM_Extern_Run & is_FSM_Extern_Ld_Run;

	// Loading from Buffer
	assign Load_Buff_St			= is_FSM_Extern_Run & is_FSM_Extern_St_Run;
	assign Load_Buff_Ld			= is_FSM_Extern_Run & is_FSM_Extern_Ld_Run;

	// Write-/Read-Enable
	assign We					= Store_Buff_St | Store_Buff_Ld;
	assign Re					= Load_Buff_St | Load_Buff_Ld;

	// Buffer Input
	assign Buff_In_Data			= ( Store_Buff_St ) ?	I_Data :
									( Store_Buff_Ld ) ?	I_Ld_Data :
														0;

	// Store Configuration
	assign O_St_Req				= Output_St_Config | ( Load_Buff_St & ~Empty );
	assign O_St_Length			= ( Output_St_Config ) ?		R_Length :				0;
	assign O_St_Stride			= ( Output_St_Config ) ?		R_Stride :				0;
	assign O_St_Base			= ( Output_St_Config ) ?		R_Base : 				0;
	assign O_St_Data			= ( Load_Buff_St & ~Empty ) ?	Buff_Data[ Rd_Ptr ] :	0;

	// Load Configuration
	assign O_Ld_Req				= Output_Ld_Config;
	assign O_Ld_Length			= ( Output_Ld_Config ) ?	R_Length :	0;
	assign O_Ld_Stride			= ( Output_Ld_Config ) ?	R_Stride :	0;
	assign O_Ld_Base			= ( Output_Ld_Config ) ?	R_Base : 	0;


	// MPU (Router)
	assign O_Req				= Load_Buff_Ld | is_FSM_Extern_St_Notify;
	assign O_Data				= ( Load_Buff_Ld ) ?				I_Data :
									( is_FSM_Extern_St_Notify ) ?	NOTIFY_DATA :
																	0;
	assign O_Rls				= ( Load_Buff_Ld ) ?				I_Ld_Term :
																	1'b0;


	// data-Memory Access-Configuration
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Stride		<= 0;
		end
		else if ( Store_Stride ) begin
			R_Stride		<= { 1'b0, I_Data[WIDTH_DATA-2:0] };
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length		<= 0;
		end
		else if ( Store_Length ) begin
			R_Length		<= I_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Base			<= 0;
		end
		else if ( Store_Base ) begin
			R_Base			<= I_Data;
		end
	end


	// Counter
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Counter_St		<= 0;
		end
		else if ( I_St_Term | I_Rls ) begin
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


	// Service Handler for Extern's Request
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Extern_Serv	<= FSM_EXTERN_INIT;
		end
		else case ( FSM_Extern_Serv )
			FSM_EXTERN_INIT: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_STRIDE;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_INIT;
				end
			end
			FSM_EXTERN_RECV_STRIDE: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_LENGTH;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_STRIDE;
				end
			end
			FSM_EXTERN_RECV_LENGTH: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_BASE;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_LENGTH;
				end
			end
			FSM_EXTERN_RECV_BASE: begin
				if ( I_Req ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_SET;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_RECV_BASE;
				end
			end
			FSM_EXTERN_RECV_SET: begin
				FSM_Extern_Serv	<= FSM_EXTERN_RUN;
			end
			FSM_EXTERN_RUN: begin
				if ( I_Ld_Term | I_St_Term | I_Rls ) begin
					FSM_Extern_Serv	<= FSM_EXTERN_INIT;
				end
				else begin
					FSM_Extern_Serv	<= FSM_EXTERN_RUN;
				end
			end
			default: begin
				FSM_Extern_Serv	<= FSM_EXTERN_INIT;
			end
		endcase
	end


	// Store Control
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Extern_St	<= FSM_EXTERN_ST_INIT;
		end
		else case ( FSM_Extern_St )
			FSM_EXTERN_ST_INIT: begin
				if ( Run_St_Service ) begin
					FSM_Extern_St	<= FSM_EXTERN_ST_BUFF;
				end
				else begin
					FSM_Extern_St	<= FSM_EXTERN_ST_INIT;
				end
			end
			FSM_EXTERN_ST_BUFF: begin
				if ( I_St_Grant ) begin
					FSM_Extern_St	<= FSM_EXTERN_ST_RUN;
				end
				else if ( Half_Buffer_Stored ) begin
					FSM_Extern_St	<= FSM_EXTERN_ST_NOTIFY;
				end
				else begin
					FSM_Extern_St	<= FSM_EXTERN_ST_BUFF;
				end
			end
			FSM_EXTERN_ST_NOTIFY: begin
					FSM_Extern_St	<= FSM_EXTERN_ST_BUFF;
			end
			FSM_EXTERN_ST_RUN: begin
				if ( I_St_Term | I_Rls ) begin
					FSM_Extern_St	<= FSM_EXTERN_ST_INIT;
				end
				else begin
					FSM_Extern_St	<= FSM_EXTERN_ST_RUN;
				end
			end
			default: begin
				FSM_Extern_St	<= FSM_EXTERN_ST_INIT;
			end
		endcase
	end


	// Load Control
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Extern_Ld	<= FSM_EXTERN_LD_INIT;
		end
		else case ( FSM_Extern_Ld )
			FSM_EXTERN_LD_INIT: begin
				if ( Run_Ld_Service ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_WAIT;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_INIT;
				end
			end
			FSM_EXTERN_LD_WAIT: begin
				if ( I_Ld_Grant ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_RUN;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_WAIT;
				end
			end
			FSM_EXTERN_LD_NOTIFY: begin
				if ( is_Ld_Notified ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_RUN;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_NOTIFY;
				end
			end
			FSM_EXTERN_LD_RUN: begin
				if ( is_Ld_Notified ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_NOTIFY;
				end
				else if ( I_Ld_Term ) begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_INIT;
				end
				else begin
					FSM_Extern_Ld	<= FSM_EXTERN_LD_RUN;
				end
			end
			default: begin
				FSM_Extern_Ld	<= FSM_EXTERN_LD_INIT;
			end
		endcase
	end


	//Store Buffer
	RingBuffCTRL #(
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