module arbiter
(
	input clk,
	input [31:0] Icache_arbiter_addr,
	input Icache_arbiter_read,
	
	input Dcache_arbiter_read,
	input Dcache_arbiter_write,
	input [31:0] Dcache_arbiter_addr,
	input [255:0] Dcache_arbiter_wdata,
	
	input l2cache_arbiter_resp,
	input [255:0] l2cache_arbiter_rdata,
	input Icache_arbiter_resp,
	input Dcache_arbiter_resp,
	
	output logic arbiter_Icache_resp,
	output logic [255:0] arbiter_Icache_rdata,
	output logic arbiter_Dcache_resp,
	output logic [255:0] arbiter_Dcache_rdata,
	
	output logic arbiter_l2cache_read,
	output logic arbiter_l2cache_write,
	output logic [255:0] arbiter_l2cache_wdata,
	output logic [31:0] arbiter_l2cache_addr
);

logic decoder_sel;
logic arbiter_addr_mux_sel;

always_comb
begin
	arbiter_Icache_rdata = l2cache_arbiter_rdata;
	arbiter_Dcache_rdata = l2cache_arbiter_rdata;
	arbiter_l2cache_wdata = Dcache_arbiter_wdata;
end

mux2 #(.width(32)) arbiter_l2cache_addr_sel
(
	.sel(arbiter_addr_mux_sel),
	.in0(Icache_arbiter_addr),
	.in1(Dcache_arbiter_addr),
	.out(arbiter_l2cache_addr)
);

decoder decoder
(
	.sel(decoder_sel),
	.in(l2cache_arbiter_resp),
	.out0(arbiter_Icache_resp),
	.out1(arbiter_Dcache_resp)
);

arbiter_control control
(
	.clk,
	.Icache_arbiter_read,
	.Dcache_arbiter_read,
	.Dcache_arbiter_write,
	.l2cache_arbiter_resp,
	.Icache_arbiter_resp,
	.Dcache_arbiter_resp,
	.arbiter_l2cache_read,
	.arbiter_l2cache_write,
	.arbiter_addr_mux_sel,
	.decoder_sel
);

endmodule : arbiter

