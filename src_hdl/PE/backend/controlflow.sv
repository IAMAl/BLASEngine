module CTRLFlow (
	input						clock,
	input						reset,
	input						I_Req,
	input						I_Stall,
	input						I_Sel_CondValid;
	input						I_CondValid1,
	input						I_CondValid2,
	input						I_Jump,
	input						I_Branch,
	input	count_t				I_Timing_MY,
	input	count_t				I_Timing_WB,
	input	state_t				I_State,
	input	cond_t				I_Cond,
	output	address_t			I_Src1,
	output	address_t			I_Src2,
	output						O_Ld,
	output	address_t			O_Address
	output						O_StallReq
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
	assign Address				= ( Taken ) ? R_Address + I_Src1 : R_Address + 1'b1;
	assign StallReq				= R_Req & ~R_Cond; ;

	assign O_Ld					= R_Req;
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
			R_Address			<= I_Src2;
		end
		else if ( Update ) begin
			R_Address			<= Address;
		end
	end

endmodule