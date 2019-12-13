module arbiter_datapath
(
	input [31:0] Icache_addr,
	input Icache_pmem_read,
	
	input Dcache_pmem_read,
	input Dcache_pmem_write,
	input [31:0] Dcache_addr,
	
	input l2cache_mem_resp,
	
	input decoder_sel,
	input arbiter_addr_mux_sel,
	
	output logic Icache_mem_resp,
	output logic Dcache_mem_resp,
	output logic [31:0] l2cache_mem_addr
);

mux2 arbiter_addr_mux
(
	.sel(arbiter_addr_mux_sel),
	.in0(Icache_addr),
	.in1(Dcache_addr),
	.out(l2cache_mem_addr)
);

decoder decoder
(
	.sel(decoder_sel),
	.in(l2cache_mem_resp),
	.out0(Icache_mem_resp),
	.out1(Dcache_mem_resp)
);

endmodule : arbiter_datapath