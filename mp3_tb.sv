module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;
logic [255:0] pmem_rdata;
logic pmem_resp;

logic [255:0] pmem_wdata;
logic [31:0] pmem_address;
logic pmem_write;
logic pmem_read;
logic pm_error;

logic [15:0] errcode;
logic [31:0] registers [32];

initial
begin
    clk = 0;
end

/* Clock generator */
always #5 clk = ~clk;

/* Registers */
assign registers = dut.cpu.regfile.data;

mp3 dut ( .* );

physical_memory physical_memory(
    .clk,
    .read(pmem_read),
    .write(pmem_write),
    .address(pmem_address),
    .wdata(pmem_wdata),
    .resp(pmem_resp),
    .error(pm_error),
    .rdata(pmem_rdata)
);


endmodule : mp3_tb