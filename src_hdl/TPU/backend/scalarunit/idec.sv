module idec (
    input                       clock,
    input                       reset,
    input   instr_t             I_Instr,
    output                      O_Stall_RegFile_Odd,
    output                      O_Stall_RegFile_Even,
    output                      O_Stall_Exec_Stall1,
    output                      O_Stall_Exec_Stall2,
    output                      O_Constant,
    output                      O_Sign,
    output                      O_Config_Path,
    output                      O_Req_RegFile_Odd,
    output                      O_Req_RegFile_Even,
    output                      O_Req_Exe_Cluster1,
    output                      O_Req_Exe_Cluster2,
    output                      O_Req_LdSt_Odd,
    output                      O_Req_LdSt_Even,
    output                      O_LdSt_Odd,
    output                      O_LdSt_Even,
    input                       I_LdSt_Done1,
    input                       I_LdSt_Done2
);

endmodule