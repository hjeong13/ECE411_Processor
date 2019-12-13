import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module eviction_write_buffer
(
	input clk,
	input logic l2cache_evicted_read,
	input logic l2cache_evicted_write,
	input logic [31:0] l2cache_evicted_address,
	input logic [255:0] l2cache_evicted_wdata,
	output logic [255:0] evicted_l2cache_rdata,
	output evicted_l2cache_mem_resp,
	input logic [255:0] pmem_evicted_rdata,
	input logic pmem_evicted_resp,
	output logic evicted_pmem_read,
	output logic evicted_pmem_write,
	output logic [31:0] evicted_pmem_address,
	output logic [255:0] evicted_pmem_wdata
);

logic valid_flag;
logic pmem_write_flag;
	
endmodule: eviction_write_buffer
