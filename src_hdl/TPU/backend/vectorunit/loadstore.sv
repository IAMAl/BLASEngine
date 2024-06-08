module LoadStoreUnit(
	input						clock,
	input						reset,
	input						I_Req,							//Flag: Activate Load/Store Unit
	input						I_Store,						//Flag: Request is Store
	input						I_Stall,						//Force Stalling by Local Memory
	input	address_t			I_Address,						//Load/Store Base Address
	input	address_t			I_Stride,						//Stride-Factor for Load/Store
	input	address_t			I_Length,						//Vector-Length for Load/Store
	output						O_St,							//Store Request
	output						O_Ld,							//Load Request
	output	address_t			O_Address,						//Access-Address
	input	data_t				I_St_Data,						//Storing Data from Register File
	output	data_t				O_St_Data,						//Store Data to Local Memory
	input	data_t				I_Ld_Data,						//Loaded Data
	output	data_t				O_Ld_Data,						//Loading Data from Local Memory
	output						O_Done							//Flag* Service is Done
);

	logic						End_Access;

	logic						R_Run;

	logic						R_We;
	logic						R_Req;
	logic						R_Store;
	logic						R_Load;
	address_t					R_Length;
	address_t					R_Stride;
	address_t					R_Address;
	data_t						St_Data;
	data_t						Ld_Data;

	assign End_Access			= R_Address == 0;

	assign O_St					= R_Store;
	assign O_Ld					= R_Load;
	assign O_Address			= R_Address;
	assign O_St_Data			= St_Data;
	assign O_Ld_Data			= Ld_Data;
	assign O_Done				= ( R_Store | R_We ) & End_Access;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else if ( ~I_Stall ) begin
			R_Req				<= I_Req;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Run				<= 1'b0;
		end
		else if ( I_Req ) begin
			R_Run				<= 1'b1;
		end
		else if ( End_Access ) begin
			R_Run				<= 1'b0;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Store				<= 1'b0;
		end
		else if ( ~I_Stall ) begin
			R_Store				<= I_Req &  I_Store;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Load				<= 1'b0;
		end
		else if ( ~I_Stall ) begin
			R_Load				<= I_Req & ~I_Store;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			St_Data				<= 0;
		end
		else if ( ~I_Stall ) begin
			St_Data				<= I_St_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_We				<= 1'b0;
		end
		else begin
			R_We				<= R_Load;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			Ld_Data				<= 0;
		end
		else if ( R_We ) begin
			Ld_Data				<= I_Ld_Data;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Stide				<=n 0;
		end
		else ( I_Req & ~R_Run ) begin
			R_Stide				<= I_Stride;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length			<= 0;
		end
		else if ( R_Run & ( R_Length > 0 ) ) begin
			R_Length			<= R_Length - 1'b1;
		end
		else ( I_Req & ~R_Run ) begin
			R_Length			<= I_Length;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Address			<= 0;
		end
		else if ( R_Run ) begin
			R_Address			<= R_Address + R_Stride;
		end
		else ( I_Req & ~R_Run ) begin
			R_Address			<= I_Address;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length			<= 0;
		end
		else if ( ( R_Length > 0 ) & ~I_Stall ) begin
			R_Length 			<= R_Length -1'b1;
		end
		else if ( I_Req & ~R_Run ) begin
			R_Length			<= I_Length;
		end
	end

endmodule