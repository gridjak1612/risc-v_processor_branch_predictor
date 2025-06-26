module fetch_cycle(clk, rst, PCSrcE, PCTargetE, InstrD, PCD, PCPlus4D, 
                   // New branch prediction signals
                   predicted_taken, predicted_target);

 
 input clk, rst;
 input PCSrcE;
 input [31:0] PCTargetE;
 output [31:0] InstrD;
 output [31:0] PCD, PCPlus4D;
 
 // New branch prediction I/O
 output predicted_taken;
 output [31:0] predicted_target;

 
 wire [31:0] PC_F, PCF, PCPlus4F;
 wire [31:0] InstrF;
 
 // New wires for branch prediction
 wire branch_inst_f;
 wire predicted_taken_f;
 wire [31:0] predicted_pc;


 reg [31:0] InstrF_reg;
 reg [31:0] PCF_reg, PCPlus4F_reg;
 
 // New registers for prediction
 reg predicted_taken_reg;
 reg [31:0] predicted_target_reg;

 // Detect if current instruction is a branch (simplified)
 assign branch_inst_f = (InstrF[6:0] == 7'b1100011); // Branch instructions

 // Instantiate branch predictor
 gshare_branch_predictor bp (
     .clk(clk),
     .rst(rst),
     .pc_f(PCF),
     .branch_inst_f(branch_inst_f),
     .predicted_taken_o(predicted_taken_f),
     .branch_resolved_e(/* connect from execute stage */),
     .actual_taken_e(/* connect from execute stage */),
     .branch_pc_e(/* connect from execute stage */),
     .branch_mispredict_e(/* connect from execute stage */)
 );

 // Predict next PC: if branch predicted taken, use predicted target
 // Otherwise use sequential PC
 assign predicted_pc = predicted_taken_f ? predicted_target_reg : PCPlus4F;

 // Modified PC Mux - now considers misprediction recovery
 Mux PC_MUX (.a(predicted_pc),
             .b(PCTargetE),
             .s(PCSrcE),  // PCSrcE now indicates misprediction recovery
             .c(PC_F)
 );

 // Rest of existing module logic...
 
 // Update registers to include prediction info
 always @(posedge clk or negedge rst) begin
    if(rst == 1'b0) begin
       InstrF_reg <= 32'h00000000;
       PCF_reg <= 32'h00000000;
       PCPlus4F_reg <= 32'h00000000;
       predicted_taken_reg <= 1'b0;
       predicted_target_reg <= 32'h00000000;
    end
    else begin
       InstrF_reg <= InstrF;
       PCF_reg <= PCF;
       PCPlus4F_reg <= PCPlus4F;
       predicted_taken_reg <= predicted_taken_f;
       // Simple target prediction: PC + immediate
       predicted_target_reg <= PCF + {{20{InstrF[31]}}, InstrF[7], InstrF[30:25], InstrF[11:8], 1'b0};
    end
 end

 // Output assignments
 assign InstrD = (rst == 1'b0) ? 32'h00000000 : InstrF_reg;
 assign PCD = (rst == 1'b0) ? 32'h00000000 : PCF_reg;
 assign PCPlus4D = (rst == 1'b0) ? 32'h00000000 : PCPlus4F_reg;
 assign predicted_taken = predicted_taken_reg;
 assign predicted_target = predicted_target_reg;

endmodule
