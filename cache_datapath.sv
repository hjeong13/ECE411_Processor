module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	
	input logic [31:0] mem_address,
	input logic [255:0] mem_wdata256,
	output logic [255:0] mem_rdata256,
	input logic mem_read,
	input logic mem_write,
	input logic [31:0] mem_byte_enable256,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	input logic [1:0] data_read_in,
	input logic [1:0] tag_read_in,
	input logic [1:0] valid_read_in,
	input logic [1:0] dirty_read_in,
	input logic lru_read_in,
	input logic [1:0] load_tag,
	input logic [1:0] load_valid,
	input logic [1:0] load_dirty,
	input logic load_lru,
	
	output logic [1:0][23:0] tag_out,
	output logic [1:0] dirty_out,
	output logic lru_out,
	
	output logic [1:0] hit,
	output logic [1:0] miss,
	input logic lru_in,
	input logic line_in_mux_sel,
	input logic [1:0] line_out_mux_sel,
	input logic dirty_in_mux_sel,
	input logic pmem_wdata_mux_sel,
	input logic [2:0] write_en_mux_sel,
	
	input logic load_stage,
	output logic mem_read_reg_out,
	output logic mem_write_reg_out,
	output logic [2:0] index_reg_out,
	output logic [31:0] mem_address_reg_out,
	input logic update_valid_tag,
	input logic rindex_mux_sel
);

logic [1:0][255:0] line_out;

logic [255:0] line_mux_out;
logic [255:0] line_in_mux_out;
logic [255:0] mem_wdata256_reg_out;

logic [23:0] tag_in;
logic [23:0] tag_in_reg_out;
logic [2:0] index_in;
logic [2:0] rindex_in;

logic [1:0][23:0] tag_out_comp;
logic [1:0] valid_out_comp;
logic [1:0] valid_out;


logic dirty_in_mux_out;
logic [63:0] write_en_mux_out;
logic [31:0] mem_byte_enable256_reg_out;


always_comb
begin
	tag_in = mem_address[31:8];
	index_in = mem_address[7:5];	
	tag_in_reg_out = mem_address_reg_out[31:8];
	index_reg_out = mem_address_reg_out[7:5];
	hit = 2'b00;
	miss = 2'b11;
	
	if(valid_out[0] == 1 && tag_out[0] == tag_in_reg_out) begin
		hit[0] = 1'b1;
		miss[0] = 1'b0;
	end
	if(valid_out[1] == 1 && tag_out[1] == tag_in_reg_out) begin
		hit[1] = 1'b1;
		miss[1] = 1'b0;
	end
end

mux2 #(.width(3)) rindex_mux
(
	.sel(rindex_mux_sel),
	.in0(index_in),
	.in1(index_reg_out),
	.out(rindex_in)
);

data_array line [1:0]
(
	.clk,
	.read(data_read_in),
	.write_en(write_en_mux_out),
	.rindex(rindex_in),
	.windex(index_reg_out),
	.datain({line_in_mux_out, line_in_mux_out}),
	.dataout(line_out)
);

/*
mux2 #(.width(256)) line_reg_mux [1:0]
(
	.sel(update_valid_tag),
	.in0(line_out),
	.in1({line_in_mux_out & {256{lru_out}},  line_in_mux_out & {256{~lru_out}}}),
	.out(line_out_comp)
);
*/
/*
register #(.width(256)) line_reg [1:0]
(
	.clk,
	.load(load_stage | update_valid_tag),
	.in(line_reg_temp_out),
	.out(line_reg_out)
);
*/

array #(.width(24)) tag [1:0]
(
	.clk,
	.read(tag_read_in),
	.load(load_tag),
	.rindex(rindex_in),
	.windex(index_reg_out),
	.datain({tag_in_reg_out, tag_in_reg_out}),
	.dataout(tag_out)
);

/*
mux2 #(.width(24)) tag_reg_mux [1:0]
(
	.sel(update_valid_tag),
	.in0(tag_out),
	.in1({tag_in_reg_out & {24{lru_out}}, tag_in_reg_out & {24{~lru_out}}}),
	.out(tag_out_comp)
);
*/

array #(.width(1)) valid [1:0]
(
	.clk,
	.read(valid_read_in),
	.load(load_valid),
	.rindex(rindex_in),
	.windex(index_reg_out),
	.datain({1'b1, 1'b1}),
	.dataout(valid_out)
);

/*
mux2 #(.width(1)) valid_reg_mux [1:0]
(
	.sel(update_valid_tag),
	.in0(valid_out),
	.in1({1'b1 & lru_out, 1'b1 & ~lru_out}),
	.out(valid_out_comp)
);
*/

array #(.width(1)) dirty [1:0]
(
	.clk,
	.read(dirty_read_in),
	.load(load_dirty),
	.rindex(rindex_in),
	.windex(index_reg_out),
	.datain({dirty_in_mux_out, dirty_in_mux_out}),
	.dataout(dirty_out)
);

/*
register #(.width(1)) dirty_reg [1:0]
(
	.clk,
	.load(load_stage),
	.in(dirty_out),
	.out(dirty_reg_out)
);
*/

array #(.width(1)) lru
(
	.clk,
	.read(lru_read_in),
	.load(load_lru),
	.rindex(rindex_in),
	.windex(index_reg_out),
	.datain(lru_in),
	.dataout(lru_out)
);
/*
register #(.width(1)) lru_reg
(
	.clk,
	.load(load_stage),
	.in(lru_out),
	.out(lru_reg_out)
);
*/

/*
register #(.width(32)) mem_address_reg_temp
(
	.clk,
	.load(1'b1),
	.in(mem_address),
	.out(mem_address_reg_temp_out)
);
*/

register #(.width(32)) mem_address_reg 
(
	.clk,
	.load(load_stage),
	.in(mem_address),
	.out(mem_address_reg_out)
);

/*
register #(.width(1)) mem_read_reg_temp
(
	.clk,
	.load(1'b1),
	.in(mem_read),
	.out(mem_read_reg_temp_out)
);
*/

register #(.width(1)) mem_read_reg 
(
	.clk,
	.load(load_stage),
	.in(mem_read),
	.out(mem_read_reg_out)
);

/*
register #(.width(1)) mem_write_reg_temp
(
	.clk,
	.load(1'b1),
	.in(mem_write),
	.out(mem_write_reg_temp_out)
);
*/

register #(.width(1)) mem_write_reg 
(
	.clk,
	.load(load_stage),
	.in(mem_write),
	.out(mem_write_reg_out)
);

/*
register #(.width(256)) mem_wdata256_reg_temp
(
	.clk,
	.load(1'b1),
	.in(mem_wdata256),
	.out(mem_wdata256_reg_temp_out)
);
*/

register #(.width(256)) mem_wdata256_reg
(
	.clk,
	.load(load_stage),
	.in(mem_wdata256),
	.out(mem_wdata256_reg_out)
);

/*
register #(.width(32)) mem_byte_enable256_reg_temp
(
	.clk,
	.load(1'b1),
	.in(mem_byte_enable256),
	.out(mem_byte_enable256_reg_temp_out)
);
*/

register #(.width(32)) mem_byte_enable256_reg
(
	.clk,
	.load(load_stage),
	.in(mem_byte_enable256),
	.out(mem_byte_enable256_reg_out)
);

mux2 #(.width(256)) line_in_mux
(
	.sel(line_in_mux_sel),
	.in0(mem_wdata256_reg_out),
	.in1(pmem_rdata),
	.out(line_in_mux_out)
);

mux4 #(.width(256)) line_out_mux
(
	.sel(line_out_mux_sel),
	.in0(256'b0),
	.in1(line_out[0]),
	.in2(line_out[1]),
	.in3(256'b0),
	.out(mem_rdata256)
);

mux2 #(.width(1)) dirty_in_mux
(
	.sel(dirty_in_mux_sel),
	.in0(1'b0),
	.in1(1'b1),
	.out(dirty_in_mux_out)
);

mux2 #(.width(256)) pmem_wdata_mux
(
	.sel(pmem_wdata_mux_sel),
	.in0(line_out[0]),
	.in1(line_out[1]),
	.out(pmem_wdata)
);

mux8 #(.width(64)) write_en_mux
(
	.sel(write_en_mux_sel),
	.in0(64'b0),
	.in1({32'b0, 32'hffffffff}),
	.in2({32'hffffffff, 32'b0}),
	.in3(64'b0),
	.in4(64'b0),
	.in5({32'b0, {mem_byte_enable256_reg_out}}),
	.in6({{mem_byte_enable256_reg_out}, 32'b0}),
	.in7(64'b0),
	.out(write_en_mux_out)
);

endmodule : cache_datapath

