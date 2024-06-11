module InstrMem
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_St,						//Store Request
	input						O_Req_St,						//Send Store State
	output	instr_t				O_ThreadID_St,					//Send Scalar Thread-ID to MapMan Unit
	output	st_address_t		O_Length_St,					//Send Storing Length to MapMan Unit
	input						I_Ack_St,						//Ack from MapMan Unit
	input	instr_t				I_Instr_St,						//Instruction
	input	st_address_t		I_Used_Size,					//Used Memory Size
	input						I_Req_Ld,						//Load Request
	input	st_address_t		I_Adddress_Ld,					//Load Address
	input	instr_t				O_Instr_Ld,						//Loaded Instruction
	output						O_Wait							//Wait: Exceeding Memory Size
);


	logic						Store;
	logic						End_Store;

	logic						R_Error_Size;
	instr_t						R_Instr_St;
	instr_t						R_Instr_Ld;
	instr_t						InstrMem		[SIZE_THREAD_MEM-1:0];

	st_address_t				R_Length_St;
	st_address_t				R_Adddress_St;


	assign O_Req_St				= FSM_Instr_St == FSM_INSTR_ST_STORE;
	assign O_ThreadID_St		= R_ThreadID_St;
	assign O_Length_St			= R_Length_St;

	assign O_Wait				= R_Error_Size;
	assign O_Instr_Ld			= R_Instr_Ld;

	assign End_Store			= R_Length_St == 0;
	assign Store				= I_Req_St & ( FSM_Instr_St == FSM_INSTR_ST_STORE );

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Instr_Ld			<= 0;
		end
		else if ( I_Req_Ld ) begin
			R_Instr_Ld			<= InstrMeme[ I_Adddress_Ld ];
		end
	end

	always_ff @( posedge clock ) begin
		if ( Store ) begin
			InstrMem[ R_Adddress_St ]	<= I_Instr_St;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Adddress_St		<= 0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_STORE ) begin
			R_Adddress_St		<= R_Adddress_St + 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID_St		<= 0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_RCVID ) begin
			R_ThreadID_St		<= I_Instr_St;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length_St			<= 0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_CHECK ) begin
			R_Length_St			<= I_Instr_St;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_STORE ) begin
			R_Length_St			<= R_Length_St - 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Error_Size		<= 1'b0;
		end
		else if ( FSM_Instr_St == FSM_INSTR_ST_CHECK ) begin
			R_Error_Size		<= ( I_Used_Size + I_Instr_St ) > SIZE_THREAD_MEM;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Instr_St	<= 0;
		end
		else case ( FSM_Instr_St )
			FSM_INSTR_ST_INIT: begin
				if ( I_Req_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_CHECK;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_INIT;
				end
			end
			FSM_INSTR_ST_CHECK: begin
				if ( I_Req_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_SETUP;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_CHECK;
				end
			end
			FSM_INSTR_ST_SETUP: begin
				FSM_Instr_St	<= FSM_INSTR_ST_RCVID;
			end
			FSM_INSTR_ST_RCVID: begin
				if ( I_Req_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_LOOKUP;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_RCVID;
				end
			end
			FSM_INSTR_ST_LOOKUP: begin
				if ( I_Ack_St ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_STORE;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_LOOKUP;
				end
			end
			FSM_INSTR_ST_STORE: begin
				if ( End_Store ) begin
					FSM_Instr_St	<= FSM_INSTR_ST_INIT;
				end
				else begin
					FSM_Instr_St	<= FSM_INSTR_ST_STORE;
				end
			end
			default: begin
				FSM_Instr_St	<= FSM_INSTR_ST_INIT;
			end
		endcase
	end

endmodule