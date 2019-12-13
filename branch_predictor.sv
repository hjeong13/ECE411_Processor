module branch_predictor
(
	input clk,
	input load_IF_ID,
	input load_ID_EX,
	input stall,
	input [6:0] IF_ID_opcode,
	input [6:0] ID_EX_opcode,
	input [31:0] pc,
	input [31:0] prev_pc,
	input result,
	
	output logic prediction
);

logic [3:0] addr;
logic [1:0] curr_counter_l, curr_counter_g;
logic [1:0] next_counter_l, next_counter_g;
logic [1:0] saved_counter_l, saved_counter_g;
logic [1:0] sel, sel_mux_out;

assign prediction = (sel_mux_out == 2'b00 || sel_mux_out == 2'b01) ? 1'b0 : 1'b1;

/**********  LOCAL   **********/
branch_history_table BHT
(
	.clk,
	.load(load_ID_EX),
	.stall(stall),
	.opcode(ID_EX_opcode),
	.index(pc[5:2]),
	.prev_index(prev_pc[5:2]),
	.in(next_counter_l),
	.out(curr_counter_l)
);

branch_counter LBC
(
	.result(result),
	.state(saved_counter_l),
	.counter(next_counter_l)
);

register #(.width(2)) local_counter_reg
(
	.clk,
	.load(load_IF_ID),
	.in(curr_counter_l),
	.out(saved_counter_l)
);

/**********  GLOBAL  **********/
global_branch_history_register GBHR
(
	.clk,
	.load(load_ID_EX),
	.stall(stall),
	.in(result),
	.opcode(ID_EX_opcode),
	.out(addr)
);

pattern_history_table PHT
(
	.clk,
	.load(load_ID_EX),
	.opcode(ID_EX_opcode),
	.stall(stall),
	//.index({pc[5:2],addr}),
	//.prev_index({prev_pc[5:2], addr}),
	.index(pc[5:2] ^ addr),
	.prev_index(prev_pc[5:2] ^ addr),
	.in(next_counter_g),
	.out(curr_counter_g)
);

branch_counter GBC
(
	.result(result),
	.state(saved_counter_g),
	.counter(next_counter_g)
);

register #(.width(2)) global_counter_reg
(
	.clk,
	.load(load_IF_ID),
	.in(curr_counter_g),
	.out(saved_counter_g)
);

/**********  SELECTOR  **********/
selector selector
(
	.clk,
	.stall(stall),
	.local_state(curr_counter_l),
	.global_state(curr_counter_g),
	.opcode(IF_ID_opcode),
	.counter(sel)
);

mux4 #(.width(2)) selector_mux
(
	.sel(sel),
	.in0(curr_counter_l),
	.in1(curr_counter_l),
	.in2(curr_counter_g),
	.in3(curr_counter_g),
	.out(sel_mux_out)
);



endmodule : branch_predictor
