module IFetch (
	input						clock,
	input						reset,
	input						I_Req,							//Enable to Work
	input						I_Empty,						//Flag: State in Empty for Buffer
	input						I_Term,							//Flag: Termination
	input	instr_t				I_Instr,						//Instruction
	output						O_Req,							//Request to Next Stage
	output	instr_t				O_Instr,						//Instruction
	output						O_Re							//Read-Enabloe for Buffer
);


	logic						We_Instr;

	logic						R_Req;
	logic						R_Req_D1;
	logic						R_Empty;
	logic						R_Term;

	instr_t						R_Insstr;
	logic						Req;


	assign O_Req				= R_Req_D1;
	assign O_Instr				= R_Instr;
	assign O_Re					= ~R_Empty;

	assign We_Instr				= Req;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req_D1		<= 1'b0;
		end
		else begin
			R_Req_D1		<= ~R_Empty;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req			<= 1'b0;
		end
		else begin
			R_Req			<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Empty			<= 1'b0;
		end
		else begin
			R_Empty			<= I_Empty;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Term			<= 1'b0;
		end
		else begin
			R_Term			<= I_Term;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Req				<= 1'b0;
		end
		else if ( R_Term ) begin
			Req				<= 1'b0;
		end
		else if ( R_Req & ~R_Empty ) begin
			Req				<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Instr			<= '0;
		end
		else if ( WE_Instr ) begin
			R_Instr			<= I_Instr;
		end
	end

endmodule
