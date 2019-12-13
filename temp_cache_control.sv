
module cache_control (
	input clk,
	
	input logic [31:0] mem_address,
	input logic mem_read,
	input logic mem_write,
	output logic mem_resp,
	
	output logic [31:0] pmem_address,
	output logic pmem_read,
	output logic pmem_write,
	input logic pmem_resp,

	output logic [1:0] data_read_in,
	output logic [1:0] tag_read_in,
	output logic [1:0] valid_read_in,
	output logic [1:0] dirty_read_in,
	output logic lru_read_in,
	
	output logic [1:0] load_tag,
	output logic [1:0] load_valid,
	output logic [1:0] load_dirty,
	output logic load_lru,
	
	input logic [1:0][23:0] tag_out_2,
	input logic [1:0] dirty_out,
	input logic lru_out,
	
	input logic [1:0] hit,
	input logic [1:0] miss,
	
	output logic lru_in,
	
	output logic line_in_mux_sel,
	output logic [1:0] line_out_mux_sel,
	
	output logic dirty_in_mux_sel,
	output logic pmem_wdata_mux_sel,
	output logic [2:0] write_en_mux_sel
	
	input logic [31:0] resp_mem_address
); 

logic [2:0] index_in;

assign index_in = mem_address[7:5];

assign resp_tag_in = resp_mem_address[31:8];
assign resp_index_in = resp_mem_address[7:5];
assign resp_offset_in = resp_mem_address[4:0];

enum int unsigned {
    /* List of states */
	idle,
	tag_check_read,
	allocate_read,
	write_back_read,
	tag_check_write,
	allocate_write,
	write_back_write
} state, next_state;

always_comb 
begin : state_action
	
	mem_resp = 1'b0;
	
	pmem_address = mem_address & 32'hfffffff8;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	
	data_read_in = 2'b0;
	tag_read_in = 2'b0;
	valid_read_in = 2'b0;
	dirty_read_in = 2'b0;
	lru_read_in = 1'b0;
	
	load_tag = 2'b0;
	load_valid = 2'b0;
	load_dirty = 2'b0;
	load_lru = 1'b0;

	line_in_mux_sel = 1'b0;
	line_out_mux_sel = 2'b00;
	dirty_in_mux_sel = 1'b0;
	pmem_wdata_mux_sel  = 1'b0;
	write_en_mux_sel = 3'b0;
	
	lru_in = 1'b0;
	load_prdata_reg = 1'b0;
	//load_mrdata256_reg = 1'b0;
	
	case(state)
		/* Parse out value from metadata arrays */
		idle : begin
			data_read_in = 2'b11;
			tag_read_in = 2'b11;
			valid_read_in = 2'b11;
			dirty_read_in = 2'b11;
			lru_read_in = 1'b1;
		end
		
		/* Read: Check tag*/
		tag_check_read : begin
			/* Cache Hit */
			if(hit[0] | hit[1]) begin
				line_out_mux_sel = hit;
					
				load_lru = 1'b1;
				if(hit[0] == 1)
					lru_in = 1'b1;
				else
					lru_in = 1'b0;

				mem_resp = 1'b1;

				/* Next Inst = read or write */
				if(mem_read | mem_write) begin
					data_read_in = 2'b11;
					tag_read_in = 2'b11;
					valid_read_in = 2'b11;
					dirty_read_in = 2'b11;
					lru_read_in = 1'b1;
				end
			end
			/* Cache Miss */
			else begin
				
			end
		end
	
		allocate_read : begin
			pmem_read = 1'b1;

			//load_prdata_reg = 1'b1;

			line_in_mux_sel = 1'b1;

			// lru = 0 : way 0 data load & lru = 1 : way 1 data load
			write_en_mux_sel = {1'b0, {lru_out}, {~lru_out}};
			
			load_valid = {lru_out, ~lru_out};
			load_tag = {lru_out, ~lru_out};
			load_dirty = {lru_out, ~lru_out};
			
			if(mem_read | mem_write)
				data_read_in = 2'b11;
				tag_read_in = 2'b11;
				valid_read_in = 2'b11;
				dirty_read_in = 2'b11;
				lru_read_in = 1'b1;
			end
		end
		
		write_back_read : begin
			pmem_wdata_mux_sel  = lru_out;
			pmem_address = {tag_out_2[lru_out], index_in, 5'b0};
		
			pmem_write = 1'b1;
		end
		
		tag_check_write : begin
			/* Next Inst = read or write */
			if(mem_read | mem_write) begin
				data_read_in = 2'b11;
				tag_read_in = 2'b11;
				valid_read_in = 2'b11;
				dirty_read_in = 2'b11;
				lru_read_in = 1'b1;
			end
			
			/* Cache Hit */
			if(hit[0] | hit[1]) begin
				line_out_mux_sel = hit;
					
				load_lru = 1'b1;
				if(hit[0] == 1)
					lru_in = 1'b1;
				else
					lru_in = 1'b0;
				
				// Write to Cache && Dirty Bit Update
				dirty_in_mux_sel = 1'b1;
					
				load_dirty = {hit[1], hit[0]};
				//load_data = {{32{hit[1]}}, {32{hit[0]}}};
					
				write_en_mux_sel = {1'b1, {hit[1]}, {hit[0]}};

				mem_resp = 1'b1;
			end
		end
	
		allocate_write : begin
			pmem_read = 1'b1;

			//load_prdata_reg = 1'b1;

			line_in_mux_sel = 1'b1;

			// lru = 0 : way 0 data load & lru = 1 : way 1 data load
			write_en_mux_sel = {1'b0, {lru_out}, {~lru_out}};
			
			load_valid = {lru_out, ~lru_out};
			load_tag = {lru_out, ~lru_out};
			load_dirty = {lru_out, ~lru_out};
			
			data_read_in = 2'b11;
			tag_read_in = 2'b11;
			valid_read_in = 2'b11;
			dirty_read_in = 2'b11;
			lru_read_in = 1'b1;
		end
		
		write_back_write : begin
			pmem_wdata_mux_sel  = lru_out;
			pmem_address = {tag_out_2[lru_out], index_in, 5'b0};
		
			pmem_write = 1'b1;
		end
		
	endcase
	
end

always_comb
begin : next_state_logic
	next_state = state;
	
	case(state)
		idle : begin
			if(mem_read)
				next_state = tag_check_read;
			else if(mem_write)
				next_state = tag_check_write;
		end
		tag_check_read : begin
			/* Cache Hit & Next Inst = read */
			if(miss != 2'b11 & mem_read)
				next_state = tag_check_read;
			/* Cache Hit & Next Inst = write */
			else if(miss != 2'b11 & mem_write)
				next_state = tag_check_write;
			/* Cache Hit & Next Inst = None Mem Ref Inst */
			else if(miss != 2'b11 & ~mem_read & ~mem_write)
				next_state = idle;
			/* Cache Miss */
			else
				next_state = (dirty_out[lru_out]) ? write_back_read : allocate_read;
		end
		allocate_read : begin
			/* Allocated & Next Inst = read */
			if(pmem_resp & mem_read)
				next_state = tag_check_read;
			/* Allocated & Next Inst = write */
			else if (pmem_resp & mem_write)
				next_state = tag_check_write;
			/* Allocated & Next Inst = None Mem Ref Inst */
			else if (pmem_resp & ~mem_read & ~mem_write)
				next_state = idle;
		end
		write_back_read : begin
			/* Evicted */
			if(pmem_resp)
				next_state = allocate_read;
		end
		tag_check_write : begin
			/* Cache Hit & Next Inst = read */
			if(miss != 2'b11 & mem_read)
				next_state = tag_check_read;
			/* Cache Hit & Next Inst = write */
			else if(miss != 2'b11 & mem_write)
				next_state = tag_check_write;
			/* Cache Hit & Next Inst = None Mem Ref Inst */
			else if(miss != 2'b11 & ~mem_read & ~mem_write)
				next_state = idle;
			/* Cache Miss */
			else
				next_state = (dirty_out[lru_out]) ? write_back_write : allocate_write;
		end
		allocate_write : begin
			/* Allocated & Next Inst = read */
			if(pmem_resp & mem_read)
				next_state = tag_check_read;
			/* Allocated & Next Inst = write */
			else if (pmem_resp & mem_write)
				next_state = tag_check_write;
			/* Allocated & Next Inst = None Mem Ref Inst */
			else if (pmem_resp & ~mem_read & ~mem_write)
				next_state = idle;
		end
		write_back_write : begin
			/* Evicted */
			if(pmem_resp)
				next_state = allocate_write;
		end
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : cache_control

