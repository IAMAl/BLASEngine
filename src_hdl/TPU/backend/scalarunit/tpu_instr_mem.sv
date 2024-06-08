module InstrMem
	import pkg_mpu::*;
(
	input							clock,
	input							reset,
	input							I_Req_St,
	input							O_Ack_St,
	input	instr_t					I_St_Instr,
	input							I_Req_Ld,
	input	st_address_t			I_Ld_Address,
	input	instr_t					OLdt_Instr
);

	instr_t							InstrMem	[SIZE_THREAD_MEM-1:0];

	assign O_Ld_Instr			= R_Instr;

	always_ff @( posedge clock ) begin
		if ( reset ) begin
			R_Instr					<= 0;
		end
		else if ( I_Req_Ld ) begin
			R_Instr					<= InstrMeme[ I_Ld_Address ];
		end
	end

	always_ff @( posedge clock ) begin
		if ( I_Req_St ) begin
			InstrMem[ St_Adddress ]	<= I_St_Instr;
		end
	end

endmodule