module DMem (
	input						clock,
	input						reset,
	input						I_Req1,							//Request Access
	input						I_Req2,							//Request Access
	input						I_St1,							//Flag Store
	input						I_St2,							//Flag Store
	input	d_address_t			I_Length1,						//Access Length
	input	d_address_t			I_Stride1,						//Stride Factor
	input	d_address_t			I_Base_Addr1,					//Base Address
	input	d_address_t			I_Length2,						//Access Length
	input	d_address_t			I_Stride2,						//Stride Factor
	input	d_address_t			I_Base_Addr2,					//Base Address
	input	data_t				I_St_Data1,						//Store Data
	input	data_t				I_St_Data2,						//Store Data
	output	data_t				O_Ld_Data1,						//Load Data
	output	data_t				O_Ld_Data2,						//Load Data
	output						O_Ack1,							//Grant Ack
	output						O_Ack2							//Grant Ack
);

	data_t						DataMem	[SIZE_DATA_MEM-1:0];

endmodule