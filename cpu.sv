import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module cpu
(
	input clk,
	
	output logic read_a,
	output logic [31:0] address_a,
	input logic resp_a,
	input logic [31:0] rdata_a,
	
	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output logic [31:0] address_b,
	output logic [31:0] wdata,
	input logic resp_b,
	input logic [31:0] rdata_b,
	output logic dcache_stall
);

logic load_pc;

logic load_IF_ID;
logic load_ID_EX;
logic load_EX_MEM;
logic load_MEM_WB;
logic prediction;

logic IF_ID_flush;
logic ID_EX_mux_sel;
logic load_forwarding_stall_reg_out;
logic load_forwarding_stall_temp;
rv32i_control_word ID_EX_ctrl_mux_out;

logic [31:0] rdata_a_new;

logic [31:0] pc_out;
logic [31:0] pc_plus4_out;
logic [31:0] pc_mux_out;
logic [31:0] prediction_mux_out;
logic [31:0] prediction_mux0_out;
logic [31:0] prediction_mux1_out;
logic [31:0] prediction_mux2_out;
logic [31:0] prediction_mux3_out;
logic [31:0] br_en_mux_out;
logic [31:0] BTB_out;
logic BTB_hit;
logic [31:0] predicted_pc_out;
logic prediction_mux0_sel;
logic prediction_mux1_sel;
logic prediction_mux3_sel;

//logic [31:0] IF_ID_pc_plus4_out;

logic [6:0] opcode;
logic [2:0] funct3;
logic [4:0] rs1;
logic [4:0] rs2;
logic [4:0] rd;
logic [31:0] rs1_out;
logic [31:0] rs2_out;

logic [159:0] imm_out;
rv32i_control_word ctrl;
logic [31:0] regfilemux_out;
logic [31:0] byte_mux_out;
logic [31:0] half_mux_out;
logic [31:0] store_mux_out;
logic [31:0] store_forward_mux_out;

logic [31:0] alu_out;
logic [31:0] alumux1_out;
logic [31:0] alumux2_out;
logic [1:0] forwardAmux_sel;
logic [1:0] forwardBmux_sel;
logic [31:0] forwardAmux_out;
logic [31:0] forwardBmux_out;
logic [31:0] cmpmux_out;
logic [1:0] cmpforwardAmux_sel;
logic [1:0] cmpforwardBmux_sel;
logic [31:0] cmpforwardAmux_out;
logic [31:0] cmpforwardBmux_out;
logic br_en;

logic IF_ID_BTB_hit_out;
logic [31:0] IF_ID_pc_out;
logic [31:0] IF_ID_BTB_out;

logic [31:0] ID_EX_pc_out;
logic [6:0] ID_EX_opcode_mux_out;
logic [6:0] ID_EX_opcode_out;
logic [2:0] ID_EX_funct3_out;
logic [4:0] ID_EX_rs1_out;
logic [4:0] ID_EX_rs2_out;
logic [31:0] ID_EX_reg_a_out;
logic [31:0] ID_EX_reg_b_out;
logic [4:0] ID_EX_rd_out;
logic [159:0] ID_EX_imm_out;
logic ID_EX_BTB_hit_out;
logic ID_EX_prediction_out;
logic [31:0] ID_EX_predicted_pc_out;
logic [31:0] ID_EX_BTB_out;
rv32i_control_word ID_EX_ctrl_out;

logic [31:0] EX_MEM_pc_out;
logic [6:0] EX_MEM_opcode_out;
logic [2:0] EX_MEM_funct3_out;
logic [4:0] EX_MEM_rs2_out;
logic [31:0] EX_MEM_reg_a_out;
logic [31:0] EX_MEM_reg_b_out;
logic [4:0] EX_MEM_rd_out;
logic [159:0] EX_MEM_imm_out;
rv32i_control_word EX_MEM_ctrl_out;
logic [31:0] EX_MEM_alu_out;
logic EX_MEM_br_en_out;

logic [31:0] MEM_WB_pc_out;
logic [6:0] MEM_WB_opcode_out;
logic [31:0] MEM_WB_reg_a_out;
logic [31:0] MEM_WB_reg_b_out;
logic [4:0] MEM_WB_rd_out;
logic [159:0] MEM_WB_imm_out;
rv32i_control_word MEM_WB_ctrl_out;
logic [31:0] MEM_WB_alu_out;
logic MEM_WB_br_en_out;
logic [31:0] MEM_WB_forward_mux_out;

logic [31:0] ID_EX_pc_plus4_out;
logic [31:0] MEM_WB_pc_plus4_out;

logic [31:0] icache_pc_out;
logic [31:0] IF_ID_pc_prev_out;

logic icache_stall;
logic forwarding_stall;
logic load_forwarding_stall;

logic EX_MEM_rdwrite;
logic MEM_WB_rdwrite;
logic Load_Store_rdwrite;
logic MEM_WB_forward_mux_sel;
logic store_forward_mux_sel;
logic icache_pc_sel;

logic IF_ID_invalidate;
logic ID_EX_invalidate;

logic [22:0] ID_EX_ctrl_temp_out;
logic IF_ID_invalidate_out;
logic ID_EX_invalidate_curr_out;
logic ID_EX_invalidate_prev_out;
logic ID_EX_load_forwarding_stall_out;

logic [31:0] rdata_a_out;
logic [31:0] rdata_a_reg_out;
logic [31:0] rdata_a_temp;

always_comb 
begin
	if(((rv32i_opcode'(MEM_WB_opcode_out) == op_load) || (rv32i_opcode'(MEM_WB_opcode_out) == op_store)) && (resp_b == 1'b0))
		dcache_stall = 1'b1;
	else
		dcache_stall = 1'b0;
	
	if(pc_out < 32'h00000064)
		icache_stall = 0;
	else if(resp_a == 0)
		icache_stall = 1;
	else 
		icache_stall = 0;
	
	/*
	load_pc = ~(icache_stall | dcache_stall | forwarding_stall);
	load_IF_ID = ~(icache_stall | dcache_stall | forwarding_stall);
	load_ID_EX = ~(dcache_stall | forwarding_stall);
	*/
	
	load_pc = ~(icache_stall | dcache_stall | load_forwarding_stall);
	load_IF_ID = ~(icache_stall | dcache_stall | load_forwarding_stall);
	
	/*
	load_ID_EX = ~(dcache_stall);
	load_EX_MEM = ~(dcache_stall);
	load_MEM_WB = ~(dcache_stall);
	*/
	
	load_ID_EX = ~(icache_stall | dcache_stall | load_forwarding_stall);
	load_EX_MEM = ~(icache_stall | dcache_stall);
	load_MEM_WB = ~(icache_stall | dcache_stall);
	
	//rdata_a_new = rdata_a & {32{~IF_ID_flush}};
	//rdata_a_new = rdata_a;
	
	read_a = 1'b1;
	//read_a = ~load_forwarding_stall;
	address_a = pc_out;
	
	pc_plus4_out = pc_out + 4;
	ID_EX_pc_plus4_out = ID_EX_pc_out + 4;
	MEM_WB_pc_plus4_out = MEM_WB_pc_out + 4;
	predicted_pc_out = IF_ID_pc_out + imm_out[95:64];
	
	/*
	opcode = rdata_a_new[6:0];
	funct3 = rdata_a_new[14:12];
	rs1 = rdata_a_new[19:15];
	rs2 = rdata_a_new[24:20];
	rd = rdata_a_new[11:7];
	*/
	
	opcode = rdata_a_temp[6:0];
	funct3 = rdata_a_temp[14:12];
	rs1 = rdata_a_temp[19:15];
	rs2 = rdata_a_temp[24:20];
	rd = rdata_a_temp[11:7];
	
	/*
	opcode = rdata_a[6:0];
	funct3 = rdata_a[14:12];
	rs1 = rdata_a[19:15];
	rs2 = rdata_a[24:20];
	rd = rdata_a[11:7];
	*/
	
	address_b = EX_MEM_alu_out;
	//wdata = store_mux_out;
	wdata = EX_MEM_reg_b_out;
	read_b = (rv32i_opcode'(EX_MEM_opcode_out) == op_load);
	write = (rv32i_opcode'(EX_MEM_opcode_out) == op_store);
	
	//IF_ID_mux_sel = 0;
	//ID_EX_mux_sel = 0;

	case(store_funct3_t'(EX_MEM_funct3_out))
		sb : begin
			case(address_b[1:0])
				2'b00 : wmask = 4'b0001;
				2'b01 : wmask = 4'b0010;
				2'b10 : wmask = 4'b0100;
				2'b11 : wmask = 4'b1000;
				default: wmask = 4'b1111;
			endcase
		end
		sh : begin
			case(address_b[1:0])
				2'b00 : wmask = 4'b0011;
				2'b10 : wmask = 4'b1100;
				default: wmask = 4'b1111;
			endcase
		end
		default : wmask = 4'b1111;
	endcase
	
	if (BTB_hit) begin
		prediction_mux0_sel = 1'b1;
		if (ID_EX_opcode_out == 7'b1101111 || ID_EX_opcode_out == 7'b1100111)
			prediction_mux0_sel = 1'b0;
	end
	else
		prediction_mux0_sel = 1'b0;
		
	if (prediction == IF_ID_BTB_hit_out) begin
		prediction_mux1_sel = 1'b1;
		if (predicted_pc_out == IF_ID_BTB_out && br_en == 1'b0 && ID_EX_prediction_out == 1'b1 && ID_EX_BTB_hit_out == 1'b0)
			prediction_mux1_sel = 1'b0;
	end
	else
		prediction_mux1_sel = 1'b0;
	
	if (br_en == ID_EX_prediction_out) begin
		prediction_mux3_sel = 1'b1;
		if (ID_EX_BTB_hit_out == 1 && ID_EX_pc_out == ID_EX_BTB_out)
			prediction_mux3_sel = 1'b0;
	end
	else
		prediction_mux3_sel = 1'b0;
end

register #(.width(1)) load_forwarding_stall_reg
(
	.clk,
	.load(1'b1),
	.in(load_forwarding_stall),
	.out(load_forwarding_stall_reg_out)
);

register rdata_a_holder
(
	.clk,
	.load(1'b1),
	.in(rdata_a),
	.out(rdata_a_out)
);

mux2 rdata_a_mux
(
	.sel(ID_EX_load_forwarding_stall_out),
	.in0(rdata_a),
	.in1(rdata_a_out),
	.out(rdata_a_new)
);

hazard_detection hd
(
	.clk,
	.br_en(br_en),
	.tag_comp(ID_EX_BTB_hit_out),
	.prediction(ID_EX_prediction_out),
	.icache_stall(icache_stall),
	.dcache_stall(dcache_stall),
	.ID_EX_invalidate_prev_out(ID_EX_invalidate_prev_out),
	.ID_EX_invalidate_curr_out(ID_EX_invalidate_curr_out),
	.opcode(opcode),
	.ID_EX_opcode_out({ID_EX_opcode_out & {7{~(ID_EX_invalidate_curr_out)}}}),
	.EX_MEM_opcode_out(EX_MEM_opcode_out),
	.rs1(rs1),
	.rs2(rs1),
	.ID_EX_rd_out(ID_EX_rd_out),
	.ID_EX_rs1_out(ID_EX_rs1_out),
	.ID_EX_rs2_out(ID_EX_rs2_out),
	.EX_MEM_rd_out(EX_MEM_rd_out),
	.ID_EX_pc_out(ID_EX_pc_out),
	.ID_EX_BTB_out(ID_EX_BTB_out),
	.predicted_pc_out(predicted_pc_out),
	.IF_ID_invalidate(IF_ID_invalidate),
	.ID_EX_invalidate(ID_EX_invalidate),
	.load_forwarding_stall(load_forwarding_stall),
	.temp(load_forwarding_stall_temp)
);
/*
hazard_detection_sbp hazard_detection_sbp
(
	.clk,
	.ID_EX_opcode_out(ID_EX_opcode_out),
	.ID_EX_invalidate_prev_out(ID_EX_invalidate_prev_out),
	.ID_EX_invalidate_curr_out(ID_EX_invalidate_curr_out),
	.br_en(br_en),
	.IF_ID_invalidate(IF_ID_invalidate),
	.ID_EX_invalidate(ID_EX_invalidate),
	.opcode(opcode),
	.rs1(rs1),
	.rs2(rs2),
	.ID_EX_rd_out(ID_EX_rd_out),
	.ID_EX_rs1_out(ID_EX_rs1_out),
	.ID_EX_rs2_out(ID_EX_rs2_out),
	.EX_MEM_rd_out(EX_MEM_rd_out),
	.icache_stall(icache_stall),
	.dcache_stall(dcache_stall),
	.EX_MEM_opcode_out(EX_MEM_opcode_out),
	.ID_EX_load_forwarding_stall_out(ID_EX_load_forwarding_stall_out),
	.load_forwarding_stall(load_forwarding_stall)
);*/

//    Fetch Stage    //
mux4 #(.width(32)) pcmux
(
	.sel(ID_EX_ctrl_out.pc_mux_sel),
	.in0(pc_plus4_out),
	.in1(alu_out & 32'hfffffffe),
	.in2(br_en_mux_out),
	.in3(32'b0),
	.out(pc_mux_out)
);

mux2 br_en_mux
(
	.sel(br_en),
	.in0(ID_EX_pc_plus4_out),
	.in1(alu_out),
	.out(br_en_mux_out)
);

logic sbp_mux_sel;
logic [31:0] sbp_target;
logic sbp_prediction;
logic ID_EX_sbp_prediction_out;
logic [31:0] sbp_mux_out0;
logic [31:0] sbp_mux_out1;

mux2 sbp_mux0
(
	.sel((br_en == 1'b0 && ID_EX_opcode_out == 7'b1100011) & ID_EX_sbp_prediction_out == 1'b1),
	.in0(pc_mux_out),
	.in1(pc_plus4_out),
	.out(sbp_mux_out0)
);

mux2 sbp_mux1
(
	.sel(sbp_mux_sel),
	.in0(sbp_mux_out0),
	.in1(sbp_target),
	.out(sbp_mux_out1)
);

mux2 prediction_mux0
(
	.sel(prediction_mux0_sel),
	.in0(pc_mux_out),
	.in1(BTB_out),
	.out(prediction_mux0_out)
);

mux2 prediction_mux1
(
	.sel(prediction_mux1_sel),
	.in0(predicted_pc_out),
	.in1(pc_plus4_out),
	.out(prediction_mux1_out)
);

mux2 prediction_mux2
(
	.sel((br_en == ID_EX_prediction_out)),
	.in0(pc_mux_out),
	.in1(pc_plus4_out),
	.out(prediction_mux2_out)
);

mux2 prediction_mux3
(
	.sel(prediction_mux3_sel),
	.in0(pc_mux_out),
	.in1(pc_plus4_out),
	.out(prediction_mux3_out)
);
//{opcode & {32{~(IF_ID_invalidate | ID_EX_invalidate_curr_out)}}}
mux4 prediction_mux
(	
	.sel({(ID_EX_opcode_out == 7'b1100011), ({opcode & {7{~(IF_ID_invalidate_out)}}} == 7'b1100011)}),
	.in0(prediction_mux0_out),
	.in1(prediction_mux1_out),
	.in2(prediction_mux2_out),
	.in3(prediction_mux3_out),
	.out(prediction_mux_out)
);

pc_register pc
(
    .clk,
    .load(load_pc),
    .in(prediction_mux_out),
    .out(pc_out)
);
/*
pc_register pc
(
    .clk,
    .load(load_pc),
    .in(prediction_mux_out),
    .out(pc_out)
);
*/
branch_target_buffer BTB
(
	.clk,
	.load(load_ID_EX),
	.prev_hit(ID_EX_BTB_hit_out),
	.br_en(br_en),
	.opcode(ID_EX_opcode_out),
	.pc(pc_out),
	.prev_pc(ID_EX_pc_out),
	.target_in(ID_EX_predicted_pc_out),
	.hit(BTB_hit),
	.out(BTB_out)
);

/***********************/

//    IF/ID    //
register IF_ID_pc
(
	.clk,
	.load(load_IF_ID),	
	.in(pc_out),
	.out(IF_ID_pc_out)
);

register #(.width(1)) IF_ID_invalidate_current
(
	.clk,
	.load(load_IF_ID),
	.in(IF_ID_invalidate),
	.out(IF_ID_invalidate_out)
);

register #(.width(1)) IF_ID_BTB_hit
(
	.clk,
	.load(load_IF_ID),
	.in(BTB_hit),
	.out(IF_ID_BTB_hit_out)
);

register IF_ID_BTB
(
	.clk,
	.load(load_IF_ID),	
	.in(BTB_out),
	.out(IF_ID_BTB_out)
);
/*
register IF_ID_pc_prev
(
	.clk,
	.load(load_IF_ID),
	.in(pc_out),
	.out(IF_ID_pc_prev_out)
);

mux2 #(.width(32)) icache_pc
(
	.sel(icache_pc_sel),
	.in0(pc_out),
	.in1(IF_ID_pc_prev_out),
	.out(icache_pc_out)
);*/


//    Decode Stage    //
regfile regfile
(
	.clk,
	.load(MEM_WB_ctrl_out.load_regfile),
	.in(regfilemux_out),
	.src_a(rs1),
	.src_b(rs2),
	.dest(MEM_WB_rd_out),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);

sext sext
(
	.data(rdata_a_temp),
	.imm(imm_out)
);

logic [22:0] ctrl_temp;

register rdata_a_reg
(
	.clk,
	.load(load_forwarding_stall),
	.in(rdata_a_new),
	.out(rdata_a_reg_out)
);

mux2 rdata_a_mux_temp
(
	.sel(load_forwarding_stall_temp),
	.in0(rdata_a_new),
	.in1(rdata_a_reg_out),
	.out(rdata_a_temp)
);

control_rom control_rom
(
	.ir(rdata_a_temp),
	.ctrl(ctrl_temp)
);

mux2 #(.width(23)) ctrl_mux
(
	.sel(IF_ID_invalidate_out),
	.in0(ctrl_temp),
	.in1(23'b0),
	.out(ctrl)
);

mux8 byte_mux
(
	.sel(MEM_WB_ctrl_out.byte_mux_sel),
	.in0({24'b0, rdata_b[7:0]}),
	.in1({24'b0, rdata_b[15:8]}),
	.in2({24'b0, rdata_b[23:16]}),
	.in3({24'b0, rdata_b[31:24]}),
	.in4({{24{rdata_b[7]}}, rdata_b[7:0]}),
	.in5({{24{rdata_b[15]}}, rdata_b[15:8]}),
	.in6({{24{rdata_b[23]}}, rdata_b[23:16]}),
	.in7({{24{rdata_b[31]}}, rdata_b[31:24]}),
	.out(byte_mux_out)
);

mux8 half_mux
(
	.sel(MEM_WB_ctrl_out.half_mux_sel),
	.in0({16'b0, rdata_b[15:0]}),
	.in1(32'b0),
	.in2({16'b0, rdata_b[31:16]}),
	.in3(32'b0),
	.in4({{16{rdata_b[15]}}, rdata_b[15:0]}),
	.in5(32'b0),
	.in6({{16{rdata_b[31]}}, rdata_b[31:16]}),
	.in7(32'b0),
	.out(half_mux_out)
);

mux8 regfilemux
(
	.sel(MEM_WB_ctrl_out.regfilemux_sel),
	.in0(MEM_WB_alu_out),
	.in1({31'b0,MEM_WB_br_en_out}),
	.in2(MEM_WB_imm_out[127:96]),   //u_imm
	.in3(rdata_b),
	.in4(MEM_WB_pc_plus4_out),
	.in5(byte_mux_out),
	.in6(half_mux_out),
	.in7(32'b0),
	.out(regfilemux_out)
);

branch_predictor branch_predictor
(
	.clk,
	.load_IF_ID(load_IF_ID),
	.load_ID_EX(load_ID_EX),
	.stall(icache_stall | dcache_stall),
	.IF_ID_opcode(opcode),
	.ID_EX_opcode(ID_EX_opcode_out),
	.pc(IF_ID_pc_out),
	.prev_pc(ID_EX_pc_out),
	.result(br_en),
	.prediction(prediction)
);
/*
static_not_taken_bp static_not_taken_bp
(
	.clk,
	.br_en(br_en),
	.opcode(opcode),
	.ID_EX_opcode_out(ID_EX_opcode_out),
	.IF_ID_invalidate_out(IF_ID_invalidate_out),
	.IF_ID_pc_out(IF_ID_pc_out),
	.sbp_mux_sel(sbp_mux_sel),
	.sbp_prediction(sbp_prediction),
	.sbp_target(sbp_target)
);
*/
/***********************/


//    ID/EX    //
register ID_EX_pc
(
	.clk,
	.load(load_ID_EX),
	.in(IF_ID_pc_out),
	.out(ID_EX_pc_out)
);

register #(.width(7)) ID_EX_opcode
(
	.clk,
	.load(load_ID_EX),
	.in(opcode),
	.out(ID_EX_opcode_out)
);

register #(.width(3)) ID_EX_funct3
(
	.clk,
	.load(load_ID_EX),
	.in(funct3),
	.out(ID_EX_funct3_out)
);

register #(.width(5)) ID_EX_rs1
(
	.clk,
	.load(load_ID_EX),
	.in(rs1),
	.out(ID_EX_rs1_out)
);

register #(.width(5)) ID_EX_rs2
(
	.clk,
	.load(load_ID_EX),
	.in(rs2),
	.out(ID_EX_rs2_out)
);

register ID_EX_reg_a
(
	.clk,
	.load(load_ID_EX),
	.in(rs1_out),
	.out(ID_EX_reg_a_out)
);

register ID_EX_reg_b
(
	.clk,
	.load(load_ID_EX),
	.in(rs2_out),
	.out(ID_EX_reg_b_out)
);

register #(.width(5)) ID_EX_rd
(
	.clk,
	.load(load_ID_EX),
	.in(rd),
	.out(ID_EX_rd_out)
);

register #(.width(160)) ID_EX_imm
(
	.clk,
	.load(load_ID_EX),
	.in(imm_out),
	.out(ID_EX_imm_out)
);

register #(.width(23)) ID_EX_ctrl
(
	.clk,
	.load(load_ID_EX),
	.in(ctrl),
	.out(ID_EX_ctrl_temp_out)
);

register #(.width(1)) ID_EX_sbp_prediction
(
	.clk,
	.load(load_ID_EX),
	.in(sbp_prediction),
	.out(ID_EX_sbp_prediction_out)
);

register #(.width(1)) ID_EX_invalidate_current
(
	.clk,
	.load(load_ID_EX),
	.in(ID_EX_invalidate),
	.out(ID_EX_invalidate_curr_out)
);

register #(.width(1)) ID_EX_invalidate_previous
(
	.clk,
	.load(load_ID_EX),
	.in(IF_ID_invalidate_out),
	.out(ID_EX_invalidate_prev_out)
);

register #(.width(1)) ID_EX_load_forwarding_stall
(
	.clk,
	.load(1'b1),
	.in(load_forwarding_stall),
	.out(ID_EX_load_forwarding_stall_out)
);

register ID_EX_BTB
(
	.clk,
	.load(load_IF_ID),	
	.in(IF_ID_BTB_out),
	.out(ID_EX_BTB_out)
);
/*
mux2 #(.width(23)) ID_EX_ctrl_mux
(
	.sel(ID_EX_mux_sel),
	.in0(ctrl),
	.in1(23'b0),
	.out(ID_EX_ctrl_mux_out)
);

register #(.width(23)) ID_EX_ctrl
(
	.clk,
	.load(load_ID_EX),
	.in(ID_EX_ctrl_mux_out),
	.out(ID_EX_ctrl_out)
);
*/
register #(.width(1)) ID_EX_BTB_hit
(
	.clk,
	.load(load_ID_EX),
	.in(IF_ID_BTB_hit_out),
	.out(ID_EX_BTB_hit_out)
);

register #(.width(1)) ID_EX_prediction
(
	.clk,
	.load(load_ID_EX),
	.in(prediction),
	.out(ID_EX_prediction_out)
);

register ID_EX_predicted_pc
(
	.clk,
	.load(load_ID_EX),
	.in(predicted_pc_out),
	.out(ID_EX_predicted_pc_out)
);

/***********************/

logic [22:0] ID_EX_ctrl_out_0;

//    Execute Stage    //
/*
mux2 #(.width(23)) EX_ctrl_mux
(
	.sel(ID_EX_invalidate_curr_out | ID_EX_invalidate_prev_out),
	.in0(ID_EX_ctrl_temp_out),
	.in1(23'b0),
	.out(ID_EX_ctrl_out_0)
);

mux2 #(.width(23)) EX_ctrl_mux_2
(
	.sel(ID_EX_load_forwarding_stall_out),
	.in0(ID_EX_ctrl_out_0),
	.in1(23'b0),
	.out(ID_EX_ctrl_out)
);
*/

mux2 #(.width(23)) EX_ctrl_mux
(
	.sel(ID_EX_invalidate_curr_out | ID_EX_invalidate_prev_out),
	.in0(ID_EX_ctrl_temp_out),
	.in1(23'b0),
	.out(ID_EX_ctrl_out)
);

logic [22:0] EX_MEM_ctrl_in;

mux2 #(.width(23)) EX_ctrl_mux_2
(
	.sel(load_forwarding_stall),
	.in0(ID_EX_ctrl_out),
	.in1(23'b0),
	.out(EX_MEM_ctrl_in)
);

logic [31:0] alu_out2;

alu ALU
(
	.aluop(ID_EX_ctrl_out.aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

alu ALU2
(
	.aluop(ID_EX_ctrl_out.aluop),
	.a(forwardAmux_out),
	.b(forwardBmux_out),
	.f(alu_out2)
);

regwrite_detection regwrite_detection
(
	.EX_MEM_opcode_out(EX_MEM_opcode_out),
	.MEM_WB_opcode_out(MEM_WB_opcode_out),
	.EX_MEM_rdwrite(EX_MEM_rdwrite),
	.MEM_WB_rdwrite(MEM_WB_rdwrite),
	.Load_Store_rdwrite(Load_Store_rdwrite),
	.MEM_WB_forward_mux_sel(MEM_WB_forward_mux_sel)
);

forwarding_unit forwarding_unit
(
	.ID_EX_rs1_out(ID_EX_rs1_out),
	.ID_EX_rs2_out(ID_EX_rs2_out),
	.ID_EX_opcode_out(ID_EX_opcode_out),
	.EX_MEM_rdwrite(EX_MEM_rdwrite),
	.EX_MEM_rd_out(EX_MEM_rd_out),
	.EX_MEM_rs2_out(EX_MEM_rs2_out),
	.MEM_WB_rdwrite(MEM_WB_rdwrite),
	.MEM_WB_rd_out(MEM_WB_rd_out),
	.Load_Store_rdwrite(Load_Store_rdwrite),
	.EX_MEM_ctrl_out(EX_MEM_ctrl_out),
	.MEM_WB_ctrl_out(MEM_WB_ctrl_out),
	.forwardAmux_sel(forwardAmux_sel),
	.forwardBmux_sel(forwardBmux_sel),
	.cmpforwardAmux_sel(cmpforwardAmux_sel),
	.cmpforwardBmux_sel(cmpforwardBmux_sel),
	.store_forward_mux_sel(store_forward_mux_sel)
);

mux2 MEM_WB_forward_mux
(
	.sel(MEM_WB_forward_mux_sel),
	.in0(MEM_WB_alu_out),
	.in1(rdata_b),
	.out(MEM_WB_forward_mux_out)
);

mux2 alumux1
(
	.sel(ID_EX_ctrl_out.alumux1_sel),
	.in0(forwardAmux_out),
	.in1(ID_EX_pc_out),
	.out(alumux1_out)
);

mux4 forwardAmux
(
	.sel(forwardAmux_sel),
	.in0(ID_EX_reg_a_out),
	.in1(EX_MEM_alu_out),
	.in2(MEM_WB_forward_mux_out),
	.in3(32'b0),
	.out(forwardAmux_out)
);

mux8 alumux2
(
	.sel(ID_EX_ctrl_out.alumux2_sel),
	.in0(ID_EX_imm_out[159:128]), // i_imm
	.in1(ID_EX_imm_out[127:96]),  // u_imm
	.in2(ID_EX_imm_out[95:64]),   // b_imm
	.in3(ID_EX_imm_out[63:32]),   // s_imm
	.in4(ID_EX_imm_out[31:0]),    // j_imm
	.in5(forwardBmux_out),
	.in6(32'b0),
	.in7(32'b0),
	.out(alumux2_out)
);

mux4 forwardBmux
(
	.sel(forwardBmux_sel),
	.in0(ID_EX_reg_b_out),
	.in1(EX_MEM_alu_out),
	.in2(MEM_WB_forward_mux_out),
	.in3(32'b0),
	.out(forwardBmux_out)
);

CMP cmp
(
	.cmpop(ID_EX_ctrl_out.cmpop),
	.rs1_out(forwardAmux_out),
	.cmpmux_out(cmpmux_out),
	.opcode(ID_EX_opcode_out),
	.br_en(br_en)
);

mux2 cmpmux
(
	.sel(ID_EX_ctrl_out.cmpmux_sel),
	.in0(forwardBmux_out),
	.in1(ID_EX_imm_out[159:128]),
	.out(cmpmux_out)
);

//    EX/MEM    //
register EX_MEM_pc
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_pc_out),
	.out(EX_MEM_pc_out)
);

register #(.width(7)) EX_MEM_opcode
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_opcode_out),
	.out(EX_MEM_opcode_out)
);

register #(.width(3)) EX_MEM_funct3
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_funct3_out),
	.out(EX_MEM_funct3_out)
);

register #(.width(5)) EX_MEM_rs2
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_rs2_out),
	.out(EX_MEM_rs2_out)
);

register EX_MEM_reg_a
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_reg_a_out),
	.out(EX_MEM_reg_a_out)
);

register EX_MEM_reg_b
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_reg_b_out),
	.out(EX_MEM_reg_b_out)
);

register #(.width(5)) EX_MEM_rd
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_rd_out),
	.out(EX_MEM_rd_out)
);

register #(.width(160)) EX_MEM_imm
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_imm_out),
	.out(EX_MEM_imm_out)
);
/*
register #(.width(23)) EX_MEM_ctrl
(
	.clk,
	.load(load_EX_MEM),
	.in(ID_EX_ctrl_out),
	.out(EX_MEM_ctrl_out)
);
*/
register #(.width(23)) EX_MEM_ctrl
(
	.clk,
	.load(load_EX_MEM),
	.in(EX_MEM_ctrl_in),
	.out(EX_MEM_ctrl_out)
);

register EX_MEM_alu
(
	.clk,
	.load(load_EX_MEM),
	.in(alu_out),
	.out(EX_MEM_alu_out)
);

logic [31:0] EX_MEM_alu_out2;
register EX_MEM_alu2
(
	.clk,
	.load(load_EX_MEM),
	.in(alu_out2),
	.out(EX_MEM_alu_out2)
);

register #(.width(1)) EX_MEM_br_en
(
	.clk,
	.load(load_EX_MEM),
	.in(br_en),
	.out(EX_MEM_br_en_out)
);
/***********************/


//    MEM Stage    //
mux2 store_forward_mux
(
	.sel(store_forward_mux_sel),
	.in0(EX_MEM_reg_b_out),
	.in1(rdata_b),
	.out(store_forward_mux_out)
);

mux4 store_mux
(
	.sel(EX_MEM_funct3_out[1:0]),
	.in0({store_forward_mux_out[7:0], store_forward_mux_out[7:0], store_forward_mux_out[7:0], store_forward_mux_out[7:0]}),
	.in1({store_forward_mux_out[15:0], store_forward_mux_out[15:0]}),
	.in2(store_forward_mux_out),
	.in3(32'b0),
	.out(store_mux_out)
);


//    MEM/WB    //
register MEM_WB_pc
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_pc_out),
	.out(MEM_WB_pc_out)
);

register #(.width(7)) MEM_WB_opcode
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_opcode_out),
	.out(MEM_WB_opcode_out)
);

register #(.width(5)) MEM_WB_rd
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_rd_out),
	.out(MEM_WB_rd_out)
);

register MEM_WB_reg_a
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_reg_a_out),
	.out(MEM_WB_reg_a_out)
);

register MEM_WB_reg_b
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_reg_b_out),
	.out(MEM_WB_reg_b_out)
);

register #(.width(160)) MEM_WB_imm
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_imm_out),
	.out(MEM_WB_imm_out)
);

register #(.width(23)) MEM_WB_ctrl
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_ctrl_out),
	.out(MEM_WB_ctrl_out)
);

register MEM_WB_alu
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_alu_out),
	.out(MEM_WB_alu_out)
);

register #(.width(1)) MEM_WB_br_en
(
	.clk,
	.load(load_MEM_WB),
	.in(EX_MEM_br_en_out),
	.out(MEM_WB_br_en_out)
);
/***********************/

logic [31:0] flush_total;

flush_count flush_count
(
	.clk,
	.IF_ID_invalidate(IF_ID_invalidate),
	.ID_EX_invalidate(ID_EX_invalidate),
	.flush_total(flush_total)
);
endmodule: cpu
