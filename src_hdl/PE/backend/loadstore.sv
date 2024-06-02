module LoadStoreUnit(
	input						clock,
	input						reset,
	input						I_Ready,						//Flag: Ready from Local Memory
	input						I_Req,							//Flag: Activate Load/Store Unit
	input						I_Store,						//Flag: Request is Store
	input	address_t			I_Address,						//Load/Store Address
	output						O_St,							//Store Request
	output						O_Ld,							//Load Request
	output	address_t			O_Address,						//Access-Address
	input	data_t				I_St_Data,						//Storing Data from Register File
	output	data_t				O_St_Data,						//Store Data to Local Memory
	input	data_t				I_Ld_Data,						//Loaded Data
	output	data_t				O_Ld_Data,						//Loading Data from Local Memory
	output						O_Done							//Flag* Service is Done
);

	logix						R_We;
	logic						R_Ready;
	logic						R_Req;
	logic						R_Store;
	logic						R_Load;
	address_t					R_Address;
	data_t						St_Data;
	data_t						Ld_Data;

	assign O_St					= R_Store;
	assign O_Ld					= R_Load;
	assign O_Address			= R_Address;
	assign O_St_Data			= St_Data;
	assign O_Ld_Data			= Ld_Data;
	assign O_Done				= R_Store | R_We;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ready				<= 1'b0;
		end
		else begin
			R_Ready				<= I_Ready;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Req				<= 1'b0;
		end
		else begin
			R_Req				<= I_Ready;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Store				<= 1'b0;
		end
		else begin
			R_Store				<= I_Req &  I_Store & R_Ready;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Load				<= 1'b0;
		end
		else begin
			R_Load				<= I_Req & ~I_Store & R_Ready;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			St_Data				<= 0;
		end
		else begin
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
			R_Address			<= 0;
		end
		else begin
			R_Address			<= I_Address;
		end
	end

endmodule