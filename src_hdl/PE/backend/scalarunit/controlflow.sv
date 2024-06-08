module CTRLFlow (
	input						clock,
	input						reset,
	input						I_Req,							//Request from Pipeline
	input						I_Stall,						//Force Stalling
	input						I_Sel_CondValid;				//Selector for CondValid-1/2
	input						I_CondValid1,					//Condition Valid
	input						I_CondValid2,					//Condition Valid
	input						I_Jump,							//Jump Instruction
	input						I_Branch,						//Branch Instruction
	input	count_t				I_Timing_MY,					//Count Value for This Instruction
	input	count_t				I_Timing_WB,					//Count Value for Write-Back Instr
	input	state_t				I_State,						//Status Register
	input	cond_t				I_Cond,							//Flag: Condition
	output	address_t			I_Src,							//Source Value
	output						O_IFetch,						//Instruction Fetch
	output	address_t			O_Address						//Address (Program COunter)
	output						O_StallReq						//Stall Request
);

	logic						Cond_Valid;
	logic						Valid;
	logic						Update;
	address_t					Address;
	logic						StallReq;

	logic						R_Req;
	logic						R_Cond;
	logic						R_CondValid;

	address_t					R_Address;

	assign Cond_Valid			= ( I_Sel_CondValid ) ? I_CondValid2 : I_CondValid1;

	assign Valid				= ( I_Timing_MY == ( I_Timing_WB + 1'b1 ) )
	assign Taken				= Valid & I_State[ I_Cond ] & I_Branch;
	assign Update				= ~I_Stall & I_Req;
	assign Address				= ( Taken ) ? R_Address + I_Src : R_Address + 1'b1;
	assign StallReq				= R_Req & ~R_Cond;

	assign O_IFetch				= R_Req;
	assign O_Address			= R_Address;
	assign O_StallReq			= StallReq;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else begin
			R_Req				<= I_Req & ~I_Stall;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Cond				<= 1'b1;
		end
		else begin
			R_Cond				<= ~R_CondValid & I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_CondValid			<= 1'b0;
		end
		else if ( StallReq ) begin
			R_CondValid			<= 1'b0;
		end
		else if ( Cond_Valid ) begin
			R_CondValid			<= 1'b1;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset) begin
			R_Address			<= 0;
		end
		else if ( I_Req & ~I_Stall & I_Jump ) begin
			R_Address			<= I_Src;
		end
		else if ( Update ) begin
			R_Address			<= Address;
		end
	end

endmodule