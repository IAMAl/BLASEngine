module MapMan
	import pkg_mpu::*;
(
	input						clock,
	input						reset,
	input						I_Req_St,						//Request from Instr Mem (Storing)
	input	id_t				I_ThreadID_St,					//Scalar Thread-ID from Instr Mem
	input	st_address_t		I_Length_St,					//Storing Size of Program
	output						O_Ack_St,						//Ack to Instr Mem
	input	id_t				I_ThreadID_Ld,					//Scalar Thread-ID from Dispat Unit
	output	st_address_t		O_Address_St,					//Base-Address fro Storing (Unnecessary?)
	input						I_Req_Ld,						//Request from Dispatch Unit
	output						O_Ack_Ld,						//Ack to Dispatch Unit
	output	lookup_t			O_ThreadInfo,					//Thread Info to Dispatch Unit
	output						O_Full							//Flag: Map-Table if Fully Used
);


	logic							Found;

	logic							We;
	logic							Re;

	logic	[SIZE_TAB_MAPMAN-1:0]	Valid;
	logic	[SIZE_TAB_MAPMAN-1:0]	is_Matched;
	logic	[WIDTH_TAB_MAPMAN-1:0]	WNo;
	logic	[WIDTH_TAB_MAPMAN-1:0]	RNo;

	st_address_t					R_Address_Ld;
	st_address_t					R_Length_Ld;
	st_address_t					R_Used_Size;

	logic							FSM_St;
	logic							FSM_Ld;


	assign O_Full           = R_Used_Size >= (SIZE_THREAD_MEM-1);

	assign Found			= |(~Valid)

	assign O_Ack_St			= ~FSM_St & Found;
	assign O_Address_St		= R_Used_Size;

	assign O_Ack_Ld			=  FSM_Ld;
	assign O_ThreadInfo.length	= R_Length_Ld;
	assign O_ThreadInfo.address	= R_Address_ld;

	assign Update           = O_Ack_St | FSM_Ld;
	assign UpdateAmount     = ( O_Ack_St & O_Ack_Ld ) ?		I_Length_St - O_Length_Ld :
								( O_Ack_St & ~O_Ack_Ld ) ?	I_Length_St :
								( ~O_Ack_St & O_Ack_Ld ) ?	0-O_Length_Ld :
															0;

	always_comb begin
		for ( int i=0; SIZE_TAB_MAPMAN; ++i ) begin
			assign Valid[ i ]		= TabInstr[ i ].Valid;
			assign is_Matched[ i ]	= Valid[ i ] & ( TanInstr[ WNo ].ThreadID == I_ThreadID_Ld );
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length_Ld		<= 0;
		end
		else if ( I_Req_Ld & ~FSM_Ld ) begin
			R_Length_Ld		<= TabInstr[ RNo ].Length
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Length_Ld		<= 0;
		end
		else if ( I_Req_Ld & ~FSM_Ld ) begin
			R_Address_Ld	<= TabInstr[ RNo ].Address
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Used_Size		<= 0;
		end
		else if ( Update ) begin
			R_Used_Size		<= R_Used_Size + UpdateAmount;
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			TabInstr			<= '0;
		end
		else if ( I_Req_St | I_Req_Ld ) begin
			if ( I_Req_St ) begin
				TabInstr[ WNo ].Valid		<= 1'b1;
				TanInstr[ WNo ].ThreadID	<= I_ThreadID_St;
				TabInstr[ WNo ].Length		<= I_Length_St;
				TabInstr[ WNo ].Address		<= R_Used_Size;
			end

			if ( I_Req_Ld ) begin
				TabInstr[ RNo ].Valid		<= 1'b0;
			end
		end
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_St			<= 1'b0;
		end
		else case ( FSM_St )
			1'b0: begin
				if ( Found ) begin
					FSM_St			<= 1'b1;
				end
				else begin
					FSM_St			<= 1'b0;
				end
			end
			1'b1: begin
				if ( I_Req_St ) begin
					FSM_St			<= 1'b0;
				end
				else begin
					FSM_St			<= 1'b1;
				end
			end
		endcase
	end

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			FSM_Ld			<= 1'b0;
		end
		else case ( FSM_Ld )
			1'b0: begin
				if ( I_Req_Ld ) begin
					FSM_Ld			<= 1'b1;
				end
				else begin
					FSM_Ld			<= 1'b0;
				end
			end
			1'b1: begin
				FSM_Ld			<= 1'b0;
			end
		endcase
	end

	//// Module: Ring-Buffer Controller
	assign WError			= I_Req_St & ~Full &  TabInstr[ WNo ].Valid;
	assign We				= I_Req_St & ~Full & ~TabInstr[ WNo ].Valid;
	assign Re				= I_Req_Ld & ~Empty;
	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_BUFF				)
	) IMemMan
	(
		.clock(				clock					),
		.reset(				reset					),
		.I_We(				We						),
		.I_Re(				Re						),
		.O_WAddr(			WNo						),
		.O_RAddr(									),
		.O_Full(			Full					),
		.O_Empty(			Empty					),
		.O_Num(										)
	);

	//// Module Encoder
	Encoder #(
		.NUM_ENTRY(			SIZE_TAB_MAMAN			)
	) LoadEntry
	(
		.I_Data(			is_Matched				),
		.O_Enc(				RNo						)
	);

endmodule