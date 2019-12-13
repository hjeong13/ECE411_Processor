module L2_cache_datapath #(
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
	
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	
	input logic [3:0] data_read_in,
	input logic [3:0] tag_read_in,
	input logic [3:0] valid_read_in,
	input logic [3:0] dirty_read_in,
	input logic lru_read_in,

	input logic [3:0] load_tag,
	input logic [3:0] load_valid,
	input logic [3:0] load_dirty,
	input logic load_lru,
	
	output logic [3:0][23:0] tag_out_2,
	output logic [3:0] dirty_out,
	output logic [2:0] lru_out,
	
	output logic [3:0] hit,
	output logic [3:0] miss,
	
	input logic [2:0] lru_in,
	
	input logic line_in_mux_sel,
	input logic [1:0] line_out_mux_sel,
	
	input logic dirty_in_mux_sel,
	input logic [1:0] pmem_wdata_mux_sel,
	input logic [2:0] write_en_mux_sel
	);

logic [3:0][255:0] line_out;
logic [255:0] line_mux_out;
logic [255:0] line_in_mux_out;
logic [255:0] pmem_rdata_reg_out;

logic [23:0] tag_in;
logic [2:0] index_in;

logic [3:0][23:0] tag_out;
logic [3:0] valid_out;

logic dirty_in_mux_out;
logic [127:0] write_en_mux_out;

assign tag_out_2 = tag_out;

always_comb
begin
	tag_in = mem_address[31:8];
	index_in = mem_address[7:5];
	
	hit = 4'b0000;
	miss = 4'b1111;
	
	if(valid_out[0] == 1 && tag_out[0] == tag_in) begin
		hit[0] = 1'b1;
		miss[0] = 1'b0;
	end
	else if(valid_out[1] == 1 && tag_out[1] == tag_in) begin
		hit[1] = 1'b1;
		miss[1] = 1'b0;
	end
	else if(valid_out[2] == 1 && tag_out[2] == tag_in) begin
		hit[2] = 1'b1;
		miss[2] = 1'b0;
	end
	else if(valid_out[3] == 1 && tag_out[3] == tag_in) begin
		hit[3] = 1'b1;
		miss[3] = 1'b0;
	end
end

L2_data_array line [3:0]
(
	.clk,
	.read(data_read_in),
	.write_en(write_en_mux_out),
	.rindex(index_in),
	.windex(index_in),
	.datain(line_in_mux_out),
	.dataout(line_out)
);

L2_array #(.width(24)) tag [3:0]
(
	.clk,
	.read(tag_read_in),
	.load(load_tag),
	.rindex(index_in),
	.windex(index_in),
	.datain(tag_in),
	.dataout(tag_out)
);

L2_array #(.width(1)) valid [3:0]
(
	.clk,
	.read(valid_read_in),
	.load(load_valid),
	.rindex(index_in),
	.windex(index_in),
	.datain(1'b1),
	.dataout(valid_out)
);

L2_array #(.width(1)) dirty [3:0]
(
	.clk,
	.read(dirty_read_in),
	.load(load_dirty),
	.rindex(index_in),
	.windex(index_in),
	.datain(dirty_in_mux_out),
	.dataout(dirty_out)
);

L2_array #(.width(3)) lru
(
	.clk,
	.read(lru_read_in),
	.load(load_lru),
	.rindex(index_in),
	.windex(index_in),
	.datain(lru_in),
	.dataout(lru_out)
);

mux2 #(.width(256)) line_in_mux
(
	.sel(line_in_mux_sel),
	.in0(mem_wdata256),
	.in1(pmem_rdata),
	.out(line_in_mux_out)
);


//fuck
mux4 #(.width(256)) line_out_mux
(
	.sel(line_out_mux_sel),
	.in0(line_out[0]),
	.in1(line_out[1]),
	.in2(line_out[2]),
	.in3(line_out[3]),
	.out(mem_rdata256)
);

mux2 #(.width(1)) dirty_in_mux
(
	.sel(dirty_in_mux_sel),
	.in0(1'b0),
	.in1(1'b1),
	.out(dirty_in_mux_out)
);

//fuck
mux4 #(.width(256)) pmem_wdata_mux
(
	.sel(pmem_wdata_mux_sel),
	.in0(line_out[0]),
	.in1(line_out[1]),
	.in2(line_out[2]),
	.in3(line_out[3]),
	.out(pmem_wdata)
);

//fuck
mux8 #(.width(128)) write_en_mux
(
	.sel(write_en_mux_sel),
	.in0(128'b0),
	.in1({32'b0, 32'b0, 32'b0, 32'hffffffff}),
	.in2({32'b0, 32'b0, 32'hffffffff, 32'b0}),
	.in3({32'b0, 32'hffffffff, 32'b0, 32'b0}),
	.in4({32'hffffffff, 32'b0, 32'b0, 32'b0}),
	.in5(128'b0),
	.in6(128'b0),
	.in7(128'b0),
	.out(write_en_mux_out)
);

endmodule : L2_cache_datapath

