module cache #(
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
	input logic [3:0] mem_byte_enable,
	input logic [31:0] mem_address,
	output logic mem_resp,
	input logic [31:0] mem_wdata,
	output logic [31:0] mem_rdata,
	
	input logic pmem_resp,
	input logic [255:0] pmem_rdata,
	output logic pmem_read,
	output logic pmem_write,
	output logic [31:0] pmem_address,
	output logic [255:0] pmem_wdata,
	input logic dcache_stall
);

logic [1:0] data_read_in;
logic [1:0] tag_read_in;
logic [1:0] valid_read_in;
logic [1:0] dirty_read_in;
logic lru_read_in;

logic [1:0] load_tag;
logic [1:0] load_valid;
logic [1:0] load_dirty;
logic load_lru;

logic [1:0][23:0] tag_out;
logic [1:0] dirty_out;
logic lru_out;
logic [1:0] hit;
logic [1:0] miss;

logic lru_in;
logic line_in_mux_sel;
logic [1:0] line_out_mux_sel;
logic dirty_in_mux_sel;
logic pmem_wdata_mux_sel;
logic [2:0] write_en_mux_sel;

logic [255:0] mem_rdata256;
logic [255:0] mem_wdata256;
logic [31:0] mem_byte_enable256;

logic load_stage;
logic mem_read_reg_out;
logic mem_write_reg_out;
logic [2:0] index_reg_out;
logic [31:0] mem_address_reg_out;

logic update_valid_tag;

logic rindex_mux_sel;

line_adapter line_adapter
(
	.mem_wdata256(mem_wdata256),
	.mem_rdata256(mem_rdata256),
	.mem_wdata(mem_wdata),
	.mem_rdata(mem_rdata),
	.mem_byte_enable(mem_byte_enable),
	.mem_byte_enable256(mem_byte_enable256),
	.resp_address(mem_address_reg_out),
	.address(mem_address)
);

cache_datapath datapath
(
	.clk,
	.mem_address(mem_address),
	.mem_wdata256(mem_wdata256),
	.mem_rdata256(mem_rdata256),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_byte_enable256(mem_byte_enable256),
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
	.tag_out(tag_out),
	.dirty_out(dirty_out),
	.lru_out(lru_out),
	.hit(hit),
	.miss(miss),
	.lru_in(lru_in),
	.line_in_mux_sel(line_in_mux_sel),
	.line_out_mux_sel(line_out_mux_sel),
	.dirty_in_mux_sel(dirty_in_mux_sel),
	.pmem_wdata_mux_sel(pmem_wdata_mux_sel),
	.write_en_mux_sel(write_en_mux_sel),
	.load_stage(load_stage),
	.mem_read_reg_out(mem_read_reg_out),
	.mem_write_reg_out(mem_write_reg_out),
	.index_reg_out(index_reg_out),
	.mem_address_reg_out(mem_address_reg_out),
	.update_valid_tag(update_valid_tag),
	.rindex_mux_sel(rindex_mux_sel)
);


cache_control control
(
	.clk,
	.mem_address(mem_address),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_read_reg_out(mem_read_reg_out),
	.mem_write_reg_out(mem_write_reg_out),
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
	.tag_out(tag_out),
	.dirty_out(dirty_out),
	.lru_out(lru_out),
	.hit(hit),
	.miss(miss),
	.lru_in(lru_in),
	.line_in_mux_sel(line_in_mux_sel),
	.line_out_mux_sel(line_out_mux_sel),
	.dirty_in_mux_sel(dirty_in_mux_sel),
	.pmem_wdata_mux_sel(pmem_wdata_mux_sel),
	.write_en_mux_sel(write_en_mux_sel),
	.load_stage(load_stage),
	.index_reg_out(index_reg_out),
	.mem_address_reg_out(mem_address_reg_out),
	.update_valid_tag(update_valid_tag),
	.dcache_stall(dcache_stall),
	.rindex_mux_sel(rindex_mux_sel)
);

endmodule : cache
