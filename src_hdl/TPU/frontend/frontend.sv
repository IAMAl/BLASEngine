module FrontEnd (
	input						clock,
	input						reset,
	input						I_En_Exe,						7yb//Enable Execution
	input						I_Req,							//Request to Work
	input						I_Full,							//Flag: State in Full in Buffer
	input						I_Term,							//Flag: Termination
	input						I_Nack,							//Nack from Back-End
	input	instr_t				I_Instr,						//Instruction
	output						O_We,							//Write-Enable for Buffer
	output	instr_t				O_ThreadID_Scalar,				//Scalar Thread-ID
	output	instr_t				O_ThreadID_SIMT,				//SIMT ThreadID
	output	instr_t				O_Instr,						//Instruction
	output						O_Term,							//Termination
	output						O_Nack							//Nack to Allocator
);


	logic						Set_We;
	logic						is_FSM_PE_RUN;

	logic						R_En_Exe;
	logic						R_Req;
	logic						R_Full;
	logic						R_Term;
	logic						R_We;
	logic						R_Nack;

	fsm_pe_frontend_t			R_FSM_PE_FRONTEND;

	instr_t						R_ThreadID_Scalar;
	instr_t						R_ThreadID_SIMT;
	instr_t						R_Instr;


	assign is_FSM_PE_SCALAR		= R_FSM_PE_FRONTEND == FSM_PE_SCALAR;
	assign is_FSM_PE_SIMT		= R_FSM_PE_FRONTEND == FSM_PE_SIMT;
	assign is_FSM_PE_INSTR		= R_FSM_PE_FRONTEND == FSM_PE_INSTR;

	assign Set_We               = ~R_Full & ( ( R_ThreadID_Scalar.v & R_Thread_SIMT.v & R_Req ) |
									( R_En_Exe & R_Req ) );

	assign O_We					= R_We;
	assign O_Instr				= R_Instr;
	assign O_ThreadID_Scalar	= R_ThreadID_Scalar;
	assign O_ThreadID_SIMT		= R_ThreadID_SIMT;
	assign O_Nack				= R_Full | R_Nack;
	assign O_Term				= is_FSM_PE_RUN & ~R_Req;

	always_ff @ ( posedge clock ) begin
		if ( reset ) begin
			R_Instr				<= '0;
		end
		else if ( R_Req ) begin
			R_Instr				<= I_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID_SIMT		<= '0;
		end
		else if ( R_Term ) begin
			R_ThreadID_SIMT		<= '0;
		end
		else if ( R_Instr.v & is_FSM_PE_SIMT ) begin
			R_ThreadID_SIMT		<= R_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_ThreadID_Scalar	<= '0;
		end
		else if ( R_Term ) begin
			R_ThreadID_Scalar	<= '0;
		end
		else if ( R_Instr.v & is_FSM_PE_SCALAR ) begin
			R_ThreadID_Scalar	<= R_Instr;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_We				<= 1'b0;
		end
		else if ( ~R_Req ) begin
			R_We				<= 1'b0;
		end
		else if ( Set_We ) begin
			R_We				<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_En_Exe			<= 1'b0;
		end
		else begin
			R_En_Exe			<= I_En_Exe;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else begin
			R_Req				<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Term				<= 1'b0;
		end
		else begin
			R_Term				<= I_Term;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Full				<= 1'b0;
		end
		else begin
			R_Full				<= I_Full;
		end
	end

	always_ff @( posedge clock ) begin
		if ( rset ) begin
			R_Nack				<= 1'b0;
		end
		else begin
			R_Nack				<= I_Nack;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_FSM_PE_FrontEnd	<= FSM_PE_FE_INIT;
		end
		else case ( R_FSM_PE_FrontEnd )
			FSM_PE_FE_INIT: begin
				if ( R_Req ) begin
					R_FSM_PE_FrontEnd	<= FSM_PE_SCALAR;
				end
				else begin
					R_FSM_PE_FrontEnd	<= FSM_PE_FE_INIT;
				end
			end
			FSM_PE_SCALAR: begin
				if ( R_Req & R_Instr.v ) begin
					R_FSM_PE_FrontEnd	<= FSM_PE_SIMT;
				end
				else begin
					R_FSM_PE_FrontEnd	<= FSM_PE_SCALAR;
				end
			end
			FSM_PE_SIMT: begin
				if ( R_Req & R_Instr.v ) begin
					R_FSM_PE_FrontEnd	<= FSM_PE_INSTR;
				end
				else begin
					R_FSM_PE_FrontEnd	<= FSM_PE_SIMT;
				end
			end
			FSM_PE_INSTR: begin
				if ( R_Term & R_Instr.v ) begin
					R_FSM_PE_FrontEnd	<= FSM_PE_INSTR;
				end
				else begin
					R_FSM_PE_FrontEnd	<= FSM_PE_SIMT;
				end
			end
			default: begin
				R_FSM_PE_FrontEnd	<= FSM_PE_FE_INIT;
			end
		endcase
	end

endmodule