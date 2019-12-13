module L2_cache_control (
	input clk,
	
	input logic [31:0] mem_address,
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp,
	
	output logic [31:0] pmem_address,
	output logic pmem_read,
	output logic pmem_write,
	input logic pmem_resp,

	output logic [3:0] data_read_in,
	output logic [3:0] tag_read_in,
	output logic [3:0] valid_read_in,
	output logic [3:0] dirty_read_in,
	output logic lru_read_in,
	
	output logic [3:0] load_tag,
	output logic [3:0] load_valid,
	output logic [3:0] load_dirty,
	output logic load_lru,
	
	input logic [3:0][23:0] tag_out_2,
	input logic [3:0] dirty_out,
	input logic [2:0] lru_out,
	
	input logic [3:0] hit,
	input logic [3:0] miss,
	
	output logic [2:0] lru_in,
	
	output logic line_in_mux_sel,
	output logic [1:0] line_out_mux_sel,
	
	output logic dirty_in_mux_sel,
	output logic [1:0] pmem_wdata_mux_sel,
	output logic [2:0] write_en_mux_sel
	); 

logic [2:0] index_in;
logic [23:0] tag_pmem_addr;

assign index_in = mem_address[7:5];

enum int unsigned {
	hit_miss_check,
	read_1,
	write_1
} state, next_state;

always_comb 
begin : state_action
	mem_resp = 1'b0;
	pmem_address = mem_address & 32'hfffffff8;
	tag_pmem_addr = 24'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	
	
	data_read_in = 4'b0;
	tag_read_in = 4'b0;
	valid_read_in = 4'b0;
	dirty_read_in = 4'b0;
	lru_read_in = 1'b0;
	
	load_tag = 4'b0;
	load_valid = 4'b0;
	load_dirty = 4'b0;
	load_lru = 1'b0;

	line_in_mux_sel = 1'b0;
	line_out_mux_sel = 2'b0;
	dirty_in_mux_sel = 1'b0;
	pmem_wdata_mux_sel  = 2'b0;
	write_en_mux_sel = 3'b0;
	
	lru_in = 3'b0;
	
	case(state)
		/* Check for hit or miss */
		hit_miss_check : begin
			/* Cache Hit */
			data_read_in = 4'b1111;
			tag_read_in = 4'b1111;
			valid_read_in = 4'b1111;
			dirty_read_in = 4'b1111;
			lru_read_in = 1'b1;
			
			if(hit[0] | hit[1] | hit[2] | hit[3]) begin
				case(hit)
					4'b0001: begin
						line_out_mux_sel = 2'b00;
						lru_in[0] = 0;
						lru_in[1] = 0;
						if(mem_write) begin
							dirty_in_mux_sel = 1'b1;
							load_dirty = dirty_out | hit;					
							write_en_mux_sel = 3'b001;
						end
					end
					4'b0010: begin
						line_out_mux_sel = 2'b01; 
						lru_in[0] = 0;
						lru_in[1] = 1;
						if(mem_write) begin
							dirty_in_mux_sel = 1'b1;
							load_dirty = dirty_out | hit;					
							write_en_mux_sel = 3'b010;
						end
					end
					4'b0100: begin
						line_out_mux_sel = 2'b10;
						lru_in[0] = 1;
						lru_in[2] = 0;
						if(mem_write) begin
							dirty_in_mux_sel = 1'b1;
							load_dirty = dirty_out | hit;					
							write_en_mux_sel = 3'b011;
						end
					end
					4'b1000: begin
						line_out_mux_sel = 2'b11;
						lru_in[0] = 1;
						lru_in[2] = 1;
						if(mem_write) begin
							dirty_in_mux_sel = 1'b1;
							load_dirty = dirty_out | hit;					
							write_en_mux_sel = 3'b100;
						end
					end
					default: ;
				endcase
				load_lru = 1'b1;
				mem_resp = 1'b1;
			end
		end
		
		read_1: begin
			pmem_read = 1'b1;
			line_in_mux_sel = 1'b1;
			if(lru_out[0] == 1) begin
				if(lru_out[1] == 1) begin
					write_en_mux_sel = 3'b001;
					load_valid = 4'b0001;
					load_tag = 4'b0001;
					load_dirty = 4'b0001;
				end
				else begin
					write_en_mux_sel = 3'b010;
					load_valid = 4'b0010;
					load_tag = 4'b0010;
					load_dirty = 4'b0010;
				end
			end
			
			else begin
				if(lru_out[2] == 1) begin
					write_en_mux_sel = 3'b011;
					load_valid = 4'b0100;
					load_tag = 4'b0100;
					load_dirty = 4'b0100;
				end
				else begin
					write_en_mux_sel = 3'b100;
					load_valid = 4'b1000;
					load_tag = 4'b1000;
					load_dirty = 4'b1000;
				end
			end
		end
		
		// Eviction (Write Back)
		write_1 : begin
			if(lru_out[0] == 1) begin
				if(lru_out[1] == 1) begin
					pmem_wdata_mux_sel = 2'b00;
					tag_pmem_addr = tag_out_2[0];
				end
				else begin
					pmem_wdata_mux_sel = 2'b01;
					tag_pmem_addr = tag_out_2[1];
				end
			end
			
			else begin
				if(lru_out[2] == 1) begin
					pmem_wdata_mux_sel = 2'b10;
					tag_pmem_addr = tag_out_2[2];
				end
				else begin
					pmem_wdata_mux_sel = 2'b11;
					tag_pmem_addr = tag_out_2[3];
				end
			end
			
			pmem_address = {tag_pmem_addr, index_in, 5'b0};
			pmem_write = 1'b1;
		end
	endcase
	
end

always_comb
begin : next_state_logic
	next_state = state;
	
	case(state)
		hit_miss_check : begin
			if(mem_read | mem_write) begin
				if(hit) next_state = hit_miss_check;
				else begin
					// neeed which one is the lru
					next_state = read_1;
					if(lru_out[0] == 1) begin
						if(lru_out[1] == 1 && dirty_out[0]) next_state = write_1;
						else if(lru_out[1] == 0 && dirty_out[1]) next_state = write_1;
					end
					else begin
						if(lru_out[2] == 1 && dirty_out[2]) next_state = write_1;
						else if(lru_out[2] == 0 && dirty_out[3]) next_state = write_1;
					end
				end
			end
		end
		read_1 : begin
			if(pmem_resp) begin
				next_state = hit_miss_check;
			end
		end

		write_1 : begin
			if(pmem_resp)
				next_state = read_1;
		end
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : L2_cache_control

