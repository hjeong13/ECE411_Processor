
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

	//input logic [1:0][31:0] load_data,
	input logic [1:0] load_tag,
	input logic [1:0] load_valid,
	input logic [1:0] load_dirty,
	input logic load_lru,
	
	output logic [1:0][23:0] tag_out_2,
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
	
	//input logic load_prdata_reg
	//input logic load_mrdata256_reg
);

logic [1:0][255:0] line_out;
logic [255:0] line_mux_out;
logic [255:0] line_in_mux_out;
logic [255:0] pmem_rdata_reg_out;

logic [23:0] tag_in;
logic [2:0] index_in;
//logic [4:0] offset_in;

logic [1:0][23:0] tag_out;
logic [1:0] valid_out;

logic dirty_in_mux_out;
logic [63:0] write_en_mux_out;

assign tag_out_2 = tag_out;

always_comb
begin
	tag_in = mem_address[31:8];
	index_in = mem_address[7:5];
	//offset_in = mem_address[4:0];
	
	hit = 2'b00;
	miss = 2'b11;
	
	if(valid_out[0] == 1 && tag_out[0] == tag_in) begin
		hit[0] = 1'b1;
		miss[0] = 1'b0;
	end
	if(valid_out[1] == 1 && tag_out[1] == tag_in) begin
		hit[1] = 1'b1;
		miss[1] = 1'b0;
	end
end

data_array line [1:0]
(
	.clk,
	.read(data_read_in),
	.write_en(write_en_mux_out),
	.index(index_in),
	.datain({line_in_mux_out, line_in_mux_out}),
	.dataout(line_out)
);

array #(.width(24)) tag [1:0]
(
	.clk,
	.read(tag_read_in),
	.load(load_tag),
	.index(index_in),
	.datain({tag_in, tag_in}),
	.dataout(tag_out)
);

array valid [1:0]
(
	.clk,
	.read(valid_read_in),
	.load(load_valid),
	.index(index_in),
	.datain({1'b1, 1'b1}),
	.dataout(valid_out)
);

array dirty [1:0]
(
	.clk,
	.read(dirty_read_in),
	.load(load_dirty),
	.index(index_in),
	.datain({dirty_in_mux_out, dirty_in_mux_out}),
	.dataout(dirty_out)
);

array lru
(
	.clk,
	.read(lru_read_in),
	.load(load_lru),
	.index(index_in),
	.datain(lru_in),
	.dataout(lru_out)
);

mux2 #(.width(256)) line_in_mux
(
	.sel(line_in_mux_sel),
	.a(mem_wdata256),
	.b(pmem_rdata),
	.f(line_in_mux_out)
);

mux4 #(.width(256)) line_out_mux
(
	.sel(line_out_mux_sel),
	.a(256'b0),
	.b(line_out[0]),
	.c(line_out[1]),
	.d(256'b0),
	.f(mem_rdata256)
);

mux2 #(.width(1)) dirty_in_mux
(
	.sel(dirty_in_mux_sel),
	.a(1'b0),
	.b(1'b1),
	.f(dirty_in_mux_out)
);

mux2 #(.width(256)) pmem_wdata_mux
(
	.sel(pmem_wdata_mux_sel),
	.a(line_out[0]),
	.b(line_out[1]),
	.f(pmem_wdata)
);

mux8 #(.width(64)) write_en_mux
(
	.sel(write_en_mux_sel),
	.in0(64'b0),
	.in1({32'b0, 32'hffffffff}),
	.in2({32'hffffffff, 32'b0}),
	.in3(64'b0),
	.in4(64'b0),
	.in5({32'b0, {mem_byte_enable256}}),
	.in6({{mem_byte_enable256}, 32'b0}),
	.in7(64'b0),
	.f(write_en_mux_out)
);

/*register #(.width(256)) pmem_rdata_reg
(
	.clk,
	.load(load_prdata_reg),
	.in(pmem_rdata),
	.out(pmem_rdata_reg_out)
);*/

/*register #(.width(256)) mem_rdata256_reg
(
	.clk,
	.load(load_mrdata256_reg),
	.in(line_mux_out),
	.out(mem_rdata256)
);*/

register address
(
);

endmodule : cache_datapath

