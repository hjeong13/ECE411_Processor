module L2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	
	input logic mem_read,
	input logic mem_write,
	input logic [31:0] mem_address,
	output logic mem_resp,
	input logic [255:0] mem_wdata,
	output logic [255:0] mem_rdata,
	
	input logic pmem_resp,
	input logic [255:0] pmem_rdata,
	output logic pmem_read,
	output logic pmem_write,
	output logic [31:0] pmem_address,
	output logic [255:0] pmem_wdata
);

logic [3:0] data_read_in;
logic [3:0] tag_read_in;
logic [3:0] valid_read_in;
logic [3:0] dirty_read_in;
logic lru_read_in;

//logic [1:0][31:0] load_data;
logic [3:0] load_tag;
logic [3:0] load_valid;
logic [3:0] load_dirty;
logic load_lru;

logic [3:0][23:0] tag_out_2;
logic [3:0] dirty_out;
logic [2:0] lru_out;

logic [3:0] hit;
logic [3:0] miss;

logic [2:0] lru_in;
logic line_in_mux_sel;
logic [1:0] line_out_mux_sel;
logic dirty_in_mux_sel;
logic [1:0] pmem_wdata_mux_sel;
logic [2:0] write_en_mux_sel;

logic [255:0] mem_rdata256;
logic [255:0] mem_wdata256;
assign mem_wdata256 = mem_wdata;
assign mem_rdata =mem_rdata256;

L2_cache_datapath datapath
(
	.clk,
	.mem_address(mem_address),
	.mem_wdata256(mem_wdata256),
	.mem_rdata256(mem_rdata256),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.pmem_rdata(pmem_rdata),
	.pmem_wdata(pmem_wdata),
	.data_read_in(data_read_in),
	.tag_read_in(tag_read_in),
	.valid_read_in(valid_read_in),
	.dirty_read_in(dirty_read_in),
	.lru_read_in(lru_read_in),
	.load_tag(load_tag),
	.load_valid(load_valid),
	.load_dirty(load_dirty),
	.load_lru(load_lru),
	.tag_out_2(tag_out_2),
	.dirty_out(dirty_out),
	.lru_out(lru_out),
	.hit(hit),
	.miss(miss),
	.lru_in(lru_in),
	.line_in_mux_sel(line_in_mux_sel),
	.line_out_mux_sel(line_out_mux_sel),
	.dirty_in_mux_sel(dirty_in_mux_sel),
	.pmem_wdata_mux_sel(pmem_wdata_mux_sel),
	.write_en_mux_sel(write_en_mux_sel)
);


L2_cache_control control
(
	.clk,
	.mem_address(mem_address),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_resp(mem_resp),
	.pmem_address(pmem_address),
	.pmem_read(pmem_read),
	.pmem_write(pmem_write),
	.pmem_resp(pmem_resp),
	.data_read_in(data_read_in),
	.tag_read_in(tag_read_in),
	.valid_read_in(valid_read_in),
	.dirty_read_in(dirty_read_in),
	.lru_read_in(lru_read_in),
	.load_tag(load_tag),
	.load_valid(load_valid),
	.load_dirty(load_dirty),
	.load_lru(load_lru),
	.tag_out_2(tag_out_2),
	.dirty_out(dirty_out),
	.lru_out(lru_out),
	.hit(hit),
	.miss(miss),
	.lru_in(lru_in),
	.line_in_mux_sel(line_in_mux_sel),
	.line_out_mux_sel(line_out_mux_sel),
	.dirty_in_mux_sel(dirty_in_mux_sel),
	.pmem_wdata_mux_sel(pmem_wdata_mux_sel),
	.write_en_mux_sel(write_en_mux_sel)
);

endmodule : L2_cache
