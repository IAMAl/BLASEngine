module MapMan(
	input										clock,
	input										reset,
	input										I_Req_St,
	input										I_Req_Ld,
	input		id_t							I_ThreadID_St,
	input		id_t							I_ThreadID_Ld,
	output									O_Ack_St,
	output									O_Ack_Ld,
	input		st_address_t				I_Length_St,
	output	st_address_t				O_Length_Ld,
	output	st_address_t				O_Address_St,
	output	st_address_t				O_Address_Ld,
	output									O_Full
);

	logic										We;
	logic										Re;

	logic	[SIZE_TAB_MAPMAN-1:0]		is_Matched;
	logic [WIDTH_TAB_MAPMAN-1:0]		WNo;
	logic [WIDTH_TAB_MAPMAN-1:0]		RNo;


	assign O_Full           = R_Used_Size >= (SIZE_THREAD_MEM-1);

	assign Update           = I_Req_St | O_Ack_Ld;
	assign UpdateAmount     = ( O_Ack_St & O_Ack_Ld ) ?	I_Length_St - O_Length_Ld :
										( O_Ack_St & ~O_Ack_Ld ) ?	I_Length_St :
										( ~O_Ack_St & O_Ack_Ld ) ?	0-O_Length_Ld :
																			0;

	always_comb begin
		for ( int i=0; SIZE_TAB_MAPMAN; ++i ) begin
			assign is_Matched[ i ]	= TabInstr[ i ].Valid & ( TanInstr[ WNo ].ThreadID == I_ThreadID_Ld );
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
				TabInstr[ WNo ].Address		<= Base_Addr_St;
			end

			if ( I_Req_Ld ) begin
				TabInstr[ RNo ].Valid		<= 1'b0;
			end
		end
	end

	//// Module: Ring-Buffer Controller
	assign WError			= I_Req_St & ~Full &  TabInstr[ WNo ].Valid;
	assign We				= I_Req_St & ~Full & ~TabInstr[ WNo ].Valid;
	assign Re				= I_Req_Ld & ~Empty;
	RingBuffCTRL #(
		.NUM_ENTRY(			DEPTH_BUFF				)
	) IMemMan
	(
		.clock(				clock						),
		.reset(				reset						),
		.I_We(				We							),
		.I_Re(				Re							),
		.O_WAddr(			WNo						),
		.O_RAddr(										),
		.O_Full(				Full						),
		.O_Empty(			Empty						),
		.O_Num(											)
	);

	//// Module Encoder
	Encoder #(
		.NUM_ENTRY(			SIZE_TAB_MAMAN			)
	) LoadEntry
	(
		.I_Data(				is_Matched				),
		.O_Enc(				RNo						)
	);

endmodule