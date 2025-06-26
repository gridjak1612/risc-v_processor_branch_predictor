module execute_cycle(
    // Existing signals
    clk, rst, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE, ALUControlE, 
    RD1_E, RD2_E, Imm_Ext_E, RD_E, PCE, PCPlus4E, PCSrcE, PCTargetE, 
    RegWriteM, MemWriteM, ResultSrcM, RD_M, PCPlus4M, WriteDataM, ALU_ResultM, 
    ResultW, ForwardA_E, ForwardB_E,
    
    // New branch prediction signals
    predicted_taken_e, predicted_target_e, branch_mispredict_e
);

 // Existing I/O declarations...
 
 // New branch prediction I/O
 input predicted_taken_e;
 input [31:0] predicted_target_e;
 output branch_mispredict_e;

 // Existing wire declarations...
 wire [31:0] Src_A, Src_B_interim, Src_B;
 wire [31:0] ResultE;
 wire ZeroE;
 
 // New wires for branch handling
 wire branch_resolved;
 wire actual_taken;
 wire mispredicted;

 // Existing register declarations...

 // Branch resolution logic
 assign branch_resolved = BranchE;
 assign actual_taken = ZeroE & BranchE;  // Actual branch outcome
 assign mispredicted = branch_resolved & (actual_taken != predicted_taken_e);
 assign branch_mispredict_e = mispredicted;

 // Existing module instantiations (ALU, muxes, etc.)...

 // Modified PC source logic
 assign PCSrcE = mispredicted;  // Redirect on misprediction
 
 // If mispredicted, use correct target; otherwise use predicted
 assign PCTargetE = mispredicted ? 
                   (actual_taken ? (PCE + Imm_Ext_E) : PCPlus4E) : 
                   predicted_target_e;

 // Rest of existing logic...

endmodule
