module CORE(
  clk,
  rst_n,
  in_valid,
  in_data,
  out_valid,
  out_data
);
input               clk;
input               rst_n;
input               in_valid;
input       [15:0]  in_data;
output reg          out_valid;
output reg  [15:0]  out_data;
// SYSTEM FSM
//parameter ST_IDLE         = 0,
//          ST_INPUT_POINT  = 1,  // cnt 1~3
//          ST_INPUT_SAMPLE = 2,  // cnt 0~4095
//          ST_CHECK        = 3,
//          ST_PARSE_SAMPLE = 4,  // mem_a 0~4095, cnt 0~2
//          ST_FIND_MIN     = 5,  // cnt 0~4
//          ST_UPDATE       = 6,
//          ST_OUTPUT       = 7;
//reg [2:0] st,nt_st;
parameter ST_IDLE   = 0,
          ST_INPUT  = 1,
          ST_OUTPUT = 2;

reg     [1:0] current_state,
              next_state;


reg     [1:0]   mem_count_in;
always @(posedge clk) begin
  if (!rst_n)
    mem_count_in <= 'd0;    
  else if ( current_state==ST_INPUT || (current_state==ST_IDLE&&in_valid) )
    mem_count_in <= mem_count_in + 'd1;
  else if(current_state == ST_IDLE)
    mem_count_in <= 'd0;
end



reg     [15:0]  mem_din;
always @(posedge clk) begin
  if (!rst_n)
    mem_din <= 'd0;        
  else if ( current_state==ST_INPUT || (current_state==ST_IDLE&&in_valid) )
    mem_din <= in_data;
  else if(current_state == ST_IDLE)
    mem_din <= 'd0;
end

reg             mem_we;
always @(posedge clk) begin
  if (!rst_n)
    mem_we <= 1'b0;        
  else if ( current_state==ST_INPUT || (current_state==ST_IDLE&&in_valid) )
    mem_we <= 1'b1;
  else if(current_state == ST_IDLE)
    mem_we <= 1'b0;
end


/*
 *  OUTPUT
 *
 */

always @(posedge clk) begin
  if (!rst_n)
    out_valid <= 1'b0;  
  else if(current_state == ST_OUTPUT)
    out_valid <= 1'b1;
  else
    out_valid <= 1'b0;
end

wire     [15:0]  mem_out;
always @(posedge clk) begin
  if (!rst_n)
    out_data <= 1'b0;  
  else if(current_state == ST_OUTPUT)
    out_data <= mem_out;
  else
    out_data <= 1'b0;
end


reg     [1:0]   mem_count_out;
always @(posedge clk) begin
  if (!rst_n)
    mem_count_out <= 'd0;    
  else if (current_state == ST_OUTPUT)
    mem_count_out <= mem_count_out + 'd1;
  else
    mem_count_out <= 'd0;
end



reg     [11:0]  mem_addr;
always @(posedge clk) begin
  if (!rst_n)
    mem_addr <= 'd0;        
  else if ( current_state==ST_INPUT || (current_state==ST_IDLE&&in_valid) )
    mem_addr <= mem_count_in;
  else if (current_state == ST_OUTPUT)
    mem_addr <= mem_count_out;
  else if(current_state == ST_IDLE)
    mem_addr <= 'd0;
end

/*
 *  FSM
 *
 */

always @(posedge clk) begin
  if (!rst_n) begin
    current_state <= ST_IDLE;    
  end
  else begin
    current_state <= next_state;
  end
end

always @(*) begin
  case(current_state)
    ST_IDLE: begin
      if(in_valid)
        next_state = ST_READY;
      else
        next_state = ST_IDLE;
    end
    ST_INPUT: begin
      if(!in_valid)
        next_state = ST_OUTPUT;
      else
        next_state = ST_INPUT;
    end
    ST_OUTPUT: begin
      if(output_done)
        next_state = ST_IDLE;
      else
        next_state = ST_OUTPUT;
    end
    default:
      next_state = ST_IDLE;
        
  endcase
end

SHAB90_4096X16X1CM16 u_SHAB90_4096X16X1CM16(
  .A    (mem_addr),
  .DI   (mem_din),
  .DO   (mem_out),
  .WEB  (mem_we),
  .CK   (clk),
  .OE   (1'd1),
  .CS   (1'd1)
);


endmodule 