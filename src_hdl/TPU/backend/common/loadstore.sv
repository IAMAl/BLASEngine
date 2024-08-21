module LoadStoreUnit
	import pkg_tpu::*;
(
	input						clock,
	input						reset,
	input						I_St_Req,						//Flag: Activate Store Unit
	input						I_Ld_Req,						//Flag: Activate Load Unit
	input						I_Store,						//Flag: Request is Store
	input						I_Stall,						//Force Stalling by Local Memory
	input	address_t			I_Length,						//Vector-Length for Load/Store
	input	address_t			I_Stride,						//Stride-Factor for Load/Store
	input	address_t			I_Base_Addr,					//Load/Store Base Address
	input						I_St_Ready,						//Flag: Ready to Store (from dmem)
	input						I_Ld_Ready,						//Flag: Ready to Load (from dmem)
	input						I_St_End_Access,				//Flag: End of Store Access (from dmem)
	input						I_Ld_End_Access,				//Flag: End of Load Access (from dmem)
	output	logic				O_St_Req,						//Store Request (to dmem)
	output	logic				O_Ld_Req,						//Load Request (to dmem)
	output	address_t			O_Length,						//Vector-Length for Load/Store
	output	address_t			O_Stride,						//Stride-Factor for Load/Store
	output	address_t			O_Base_Addr						//Load/Store Base Address
	output	logic				O_St_Rd_RF						//Read-Enable to RF units, update index
	output	logic				O_Ld_Wr_RF						//Write-Enable to RF units, update index
	output	logic				O_St_Valid,						//Flag: Valid Data to Store (to dmem)
	input	data_t				I_St_Data,						//Storing Data from Register File
	output	data_t				O_St_Data,						//Store Data to Local Memory (to dmem)
	output	logic				O_Ld_Valid,						//Flag: Request Loadinng (to dmem)
	input	data_t				I_Ld_Data,						//Loaded Data (from dmem)
	output	data_t				O_Ld_Data,						//Loading Data from Local Memory (to RF)
	output	logic				O_St_End,						//Flag: Service is Done
	output	logic				O_Ld_End						//Flag: Service is Done
);


	logic						R_St_Active;
	logic						R_Ld_Active;

	logic						R_St_End;
	logic						R_Ld_End;

	address_t					R_Length;
	address_t					R_Stride;
	address_t					R_Base_Addr;

	data_t						St_Data;
	data_t						Ld_Data;


	assign O_St_Req				= R_St_Active;
	assign O_Ld_Req				= R_Ld_Active;
	assign O_St_End				= R_St_End;
	assign O_Ld_End				= R_Ld_End;

	assign O_Length				= R_Length;
	assign O_Stride				= R_Stride;
	assign O_Base_Addr			= R_Base_Addr;

	assign O_St_Rd_RF			= R_St_Active & ~I_Stall & I_St_Ready;
	assign O_St_Valid			= R_St_Active & ~I_Stall;
	assign O_St_Data			= St_Data;

	assign O_Ld_Wr_RF			= R_Ld_Active & ~I_Stall & I_Ld_Ready;
	assign O_Ld_Valid			= R_Ld_Active & ~I_Stall;
	assign O_Ld_Data			= Ld_Data;


	assign O_Done				= ( R_Store | R_We ) & End_Access;

	assign O_Ld_NoReady			= R_Run & ~I_Ack_Ld;


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_Active				<= 1'b0;
		end
		else if ( I_St_End_Access ) begin
			R_St_Active				<=  1'b0;
		end
		else if ( I_St_Req ) begin
			R_St_Active				<=  1'b1;
		end
	end


	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_Active				<= 1'b0;
		end
		else if ( ILdt_End_Access ) begin
			R_Ld_Active				<=  1'b0;
		end
		else if ( I_Ld_Req ) begin
			R_Ld_Active				<=  1'b1;
		end
	end


	//// Capture End of Service
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_St_End			<= 1'b0;
		end
		elzze begin
			R_St_End			<= I_St_End_Access;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Ld_End			<= 1'b0;
		end
		elzze begin
			R_Ld_End			<= I_Ld_End_Access;
		end
	end


	//// Capture Load/Store Data for Transfer
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
			Ld_Data				<= 0;
		end
		else if ( R_We ) begin
			Ld_Data				<= I_Ld_Data;
		end
	end


	//// Capture Access-Configuration
	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length			<= 0;
		end
		else ( I_Req & ~R_Run ) begin
			R_Length			<= I_Length;
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
			R_Address			<= 0;
		end
		else ( I_Req & ~R_Run ) begin
			R_Base_Addr			<= I_Base_Addr;
		end
	end

endmodule