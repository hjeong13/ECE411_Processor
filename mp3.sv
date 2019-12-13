import rv32i_types::*; /* Import types defined in rv32i_types.sv */

module mp3
(
	input clk,
	input [255:0] pmem_rdata,
	input pmem_resp,
	
	output logic [255:0] pmem_wdata,
	output logic [31:0] pmem_address,
	output logic pmem_write,
	output logic pmem_read
);

logic read_a;
logic [31:0] address_a;
logic resp_a;
logic [31:0] rdata_a;

logic read_b;
logic write;
logic [3:0] wmask;
logic [31:0] address_b;
logic [31:0] wdata;
logic resp_b;
logic [31:0] rdata_b;

logic [255:0] temp;
logic [255:0] Dcache_arbiter_wdata;
logic [31:0] pmem_address_a;
logic [31:0] pmem_address_b;
logic Icache_pmem_read;
logic Icache_pmem_write;
logic Dcache_pmem_read;
logic Dcache_pmem_write;
logic Icache_mem_resp;
logic Dcache_mem_resp;
logic [255:0] arbiter_Dcache_rdata;
logic [255:0] arbiter_Icache_rdata;


logic arbiter_l2cache_read;
logic arbiter_l2cache_write;
logic [31:0] arbiter_l2cache_addr;
logic l2cache_arbiter_resp;
logic [255:0] arbiter_l2cache_wdata;
logic [255:0] l2cache_arbiter_rdata;
logic dcache_stall;

cpu cpu
(
	.clk,
	.read_a(read_a),
	.address_a(address_a),
	.resp_a(resp_a),
	.rdata_a(rdata_a),
	.read_b(read_b),
	.write(write),
	.wmask(wmask),
	.address_b(address_b),
	.wdata(wdata),
	.resp_b(resp_b),
	.rdata_b(rdata_b),
	.dcache_stall(dcache_stall)
);

cache Icache
(
	.clk,
	.mem_read(read_a),
	.mem_write(1'b0),
	.mem_byte_enable(4'b1111),
	.mem_address(address_a),
	.mem_resp(resp_a),
	.mem_wdata(32'b0),
	.mem_rdata(rdata_a),
	.pmem_resp(Icache_mem_resp),
	.pmem_rdata(arbiter_Icache_rdata),
	.pmem_read(Icache_pmem_read),
	.pmem_write(Icache_pmem_write),
	.pmem_address(pmem_address_a),
	.pmem_wdata(temp),
	.dcache_stall(dcache_stall)
);

cache Dcache
(
	.clk,
	.mem_read(read_b),
	.mem_write(write),
	.mem_byte_enable(wmask),
	.mem_address(address_b),
	.mem_resp(resp_b),
	.mem_wdata(wdata),
	.mem_rdata(rdata_b),
	.pmem_resp(Dcache_mem_resp),
	.pmem_rdata(arbiter_Dcache_rdata),
	.pmem_read(Dcache_pmem_read),
	.pmem_write(Dcache_pmem_write),
	.pmem_address(pmem_address_b),
	.pmem_wdata(Dcache_arbiter_wdata),
	.dcache_stall(1'b0)
);

arbiter arbiter
(
	.clk,
	.Icache_arbiter_addr(pmem_address_a),
	.Icache_arbiter_read(Icache_pmem_read),
	.Dcache_arbiter_read(Dcache_pmem_read),
	.Dcache_arbiter_write(Dcache_pmem_write),
	.Dcache_arbiter_addr(pmem_address_b),
	.Dcache_arbiter_wdata(Dcache_arbiter_wdata),
	
	.l2cache_arbiter_resp(l2cache_arbiter_resp),	//
	.l2cache_arbiter_rdata(l2cache_arbiter_rdata),	//
	.Icache_arbiter_resp(resp_a),
	.Dcache_arbiter_resp(resp_b),
	.arbiter_Icache_resp(Icache_mem_resp),
	.arbiter_Icache_rdata(arbiter_Icache_rdata),
	.arbiter_Dcache_resp(Dcache_mem_resp),
	.arbiter_Dcache_rdata(arbiter_Dcache_rdata),
	.arbiter_l2cache_read(arbiter_l2cache_read),
	.arbiter_l2cache_write(arbiter_l2cache_write),
	.arbiter_l2cache_wdata(arbiter_l2cache_wdata),
	.arbiter_l2cache_addr(arbiter_l2cache_addr)
);


L2_cache L2_cache
(
	.clk,
	.mem_read(arbiter_l2cache_read),
	.mem_write(arbiter_l2cache_write),
	.mem_address(arbiter_l2cache_addr),
	.mem_resp(l2cache_arbiter_resp),
	.mem_wdata(arbiter_l2cache_wdata),
	.mem_rdata(l2cache_arbiter_rdata),
	.pmem_resp(pmem_resp),
	.pmem_rdata(pmem_rdata),
	.pmem_read(pmem_read),
	.pmem_write(pmem_write),
	.pmem_address(pmem_address),
	.pmem_wdata(pmem_wdata)
);


endmodule : mp3

