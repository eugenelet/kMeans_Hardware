`include "SAD.v"
module CORE(
  clk,
  rst_n,
  in_valid,
  in_data,
  out_valid,
  out_data
);
input           clk;
input           rst_n;
input           in_valid;
input   [15:0]  in_data;
output          out_valid;
output  [15:0]  out_data;
// SYSTEM FSM
parameter ST_IDLE         = 0,
          ST_INPUT_POINT  = 1,  // cnt 1~3
          ST_INPUT_SAMPLE = 2,  // cnt 0~4095
          ST_CHECK        = 3,
          ST_PARSE_SAMPLE = 4,  // mem_a 0~4095, cnt 0~2
          ST_FIND_MIN     = 5,  // cnt 0~4
          ST_UPDATE       = 6,
          ST_OUTPUT       = 7;
reg [2:0] st,nt_st;
// DEBUG SIGNAL
reg [9:0] iteration;
always @(posedge clk) begin
  if(!rst_n)
    iteration <= 'd0;
  else if(st==ST_IDLE)
    iteration <= 'd0;
  else if(st==ST_CHECK)
    iteration <= iteration+'d1;
end
// memory signal
wire  [15:0]  mem_q;
reg           mem_we_n;
reg   [11:0]  mem_a;
reg   [15:0]  mem_d;
reg   [7:0]   mem_q_x,mem_q_y;
// counter for data input and output
reg [11:0]  cnt;
always @(posedge clk) begin
  if(!rst_n)
    cnt <= 'd0;
  else
    case(st)
      ST_IDLE: begin
        if(in_valid)
          cnt <= 'd1;
        else
          cnt <= 'd0;
      end
      ST_INPUT_POINT: begin
        if(cnt=='d3)
          cnt <= 'd0;
        else if(in_valid)
          cnt <= cnt+'d1;
      end
      ST_INPUT_SAMPLE: begin
        if(in_valid)
          cnt <= cnt+'d1;
      end
      ST_CHECK: begin
        cnt <= 'd0;
      end
      ST_PARSE_SAMPLE: begin
        if(cnt=='d2)
          cnt <= 'd0;
        else
          cnt <= cnt+'d1;
      end
      ST_FIND_MIN: begin
        if(cnt=='d4)
          cnt <= 'd0;
        else
          cnt <= cnt+'d1;
      end
      ST_OUTPUT: begin
        cnt <= cnt+'d1;
      end
    endcase
end
// 4 points for K-means and K is 4
reg [7:0]   pre_x_0,pre_y_0;
reg [7:0]   pre_x_1,pre_y_1;
reg [7:0]   pre_x_2,pre_y_2;
reg [7:0]   pre_x_3,pre_y_3;
reg [7:0]   cur_x_0,cur_y_0;
reg [7:0]   cur_x_1,cur_y_1;
reg [7:0]   cur_x_2,cur_y_2;
reg [7:0]   cur_x_3,cur_y_3;
reg [11:0]  point_0,point_1,point_2,point_3;
reg [19:0]  sum_x_0,sum_y_0;
reg [19:0]  sum_x_1,sum_y_1;
reg [19:0]  sum_x_2,sum_y_2;
reg [19:0]  sum_x_3,sum_y_3;
always @(posedge clk) begin
  if(!rst_n) begin
    pre_x_0 <= 'd0;
    pre_y_0 <= 'd0;
    pre_x_1 <= 'd0;
    pre_y_1 <= 'd0;
    pre_x_2 <= 'd0;
    pre_y_2 <= 'd0;
    pre_x_3 <= 'd0;
    pre_y_3 <= 'd0;
  end
  else if(st==ST_UPDATE) begin
    pre_x_0 <= cur_x_0;
    pre_y_0 <= cur_y_0;
    pre_x_1 <= cur_x_1;
    pre_y_1 <= cur_y_1;
    pre_x_2 <= cur_x_2;
    pre_y_2 <= cur_y_2;
    pre_x_3 <= cur_x_3;
    pre_y_3 <= cur_y_3;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    cur_x_0 <= 'd0;
    cur_y_0 <= 'd0;
  end
  else if(st==ST_IDLE && in_valid && cnt=='d0) begin
    cur_x_0 <= in_data[15:8];
    cur_y_0 <= in_data[7:0];
  end
  else if(st==ST_UPDATE && point_0>'d0) begin
    cur_x_0 <= sum_x_0/point_0;
    cur_y_0 <= sum_y_0/point_0;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    cur_x_1 <= 'd0;
    cur_y_1 <= 'd0;
  end
  else if(st==ST_INPUT_POINT && in_valid && cnt=='d1) begin
    cur_x_1 <= in_data[15:8];
    cur_y_1 <= in_data[7:0];
  end
  else if(st==ST_UPDATE && point_1>'d0) begin
    cur_x_1 <= sum_x_1/point_1;
    cur_y_1 <= sum_y_1/point_1;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    cur_x_2 <= 'd0;
    cur_y_2 <= 'd0;
  end
  else if(st==ST_INPUT_POINT && in_valid && cnt=='d2) begin
    cur_x_2 <= in_data[15:8];
    cur_y_2 <= in_data[7:0];
  end
  else if(st==ST_UPDATE && point_2>'d0) begin
    cur_x_2 <= sum_x_2/point_2;
    cur_y_2 <= sum_y_2/point_2;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    cur_x_3 <= 'd0;
    cur_y_3 <= 'd0;
  end
  else if(st==ST_INPUT_POINT && in_valid && cnt=='d3) begin
    cur_x_3 <= in_data[15:8];
    cur_y_3 <= in_data[7:0];
  end
  else if(st==ST_UPDATE && point_3>'d0) begin
    cur_x_3 <= sum_x_3/point_3;
    cur_y_3 <= sum_y_3/point_3;
  end
end
wire  [7:0] p_x;
wire  [7:0] p_y;
wire  [8:0] ans;
assign p_x  = (st==ST_FIND_MIN && cnt==0)?  cur_x_0:
              (st==ST_FIND_MIN && cnt==1)?  cur_x_1:
              (st==ST_FIND_MIN && cnt==2)?  cur_x_2:
                                            cur_x_3;
assign p_y  = (st==ST_FIND_MIN && cnt==0)?  cur_y_0:
              (st==ST_FIND_MIN && cnt==1)?  cur_y_1:
              (st==ST_FIND_MIN && cnt==2)?  cur_y_2:
                                            cur_y_3;
reg [1:0] min_idx;
reg [8:0] min_dis;
always @(posedge clk) begin
  if(!rst_n) begin
    min_idx <= 'd0;
    min_dis <= 'd0;
  end
  else if((st==ST_FIND_MIN && cnt=='d0) || (st==ST_FIND_MIN && cnt<'d4 && ans<min_dis)) begin
    min_idx <= cnt;
    min_dis <= ans;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    point_0 <= 'd0;
    sum_x_0 <= 'd0;
    sum_y_0 <= 'd0;
  end
  else if(st==ST_CHECK) begin
    point_0 <= 'd0;
    sum_x_0 <= 'd0;
    sum_y_0 <= 'd0;
  end
  else if(st==ST_FIND_MIN && cnt=='d4 && min_idx=='d0) begin
    point_0 <= point_0+'d1;
    sum_x_0 <= sum_x_0+mem_q_x;
    sum_y_0 <= sum_y_0+mem_q_y;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    point_1 <= 'd0;
    sum_x_1 <= 'd0;
    sum_y_1 <= 'd0;
  end
  else if(st==ST_CHECK) begin
    point_1 <= 'd0;
    sum_x_1 <= 'd0;
    sum_y_1 <= 'd0;
  end
  else if(st==ST_FIND_MIN && cnt=='d4 && min_idx=='d1) begin
    point_1 <= point_1+'d1;
    sum_x_1 <= sum_x_1+mem_q_x;
    sum_y_1 <= sum_y_1+mem_q_y;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    point_2 <= 'd0;
    sum_x_2 <= 'd0;
    sum_y_2 <= 'd0;
  end
  else if(st==ST_CHECK) begin
    point_2 <= 'd0;
    sum_x_2 <= 'd0;
    sum_y_2 <= 'd0;
  end
  else if(st==ST_FIND_MIN && cnt=='d4 && min_idx=='d2) begin
    point_2 <= point_2+'d1;
    sum_x_2 <= sum_x_2+mem_q_x;
    sum_y_2 <= sum_y_2+mem_q_y;
  end
end
always @(posedge clk) begin
  if(!rst_n) begin
    point_3 <= 'd0;
    sum_x_3 <= 'd0;
    sum_y_3 <= 'd0;
  end
  else if(st==ST_CHECK) begin
    point_3 <= 'd0;
    sum_x_3 <= 'd0;
    sum_y_3 <= 'd0;
  end
  else if(st==ST_FIND_MIN && cnt=='d4 && min_idx=='d3) begin
    point_3 <= point_3+'d1;
    sum_x_3 <= sum_x_3+mem_q_x;
    sum_y_3 <= sum_y_3+mem_q_y;
  end
end
// memory control
always @(posedge clk) begin
  if(!rst_n)
    mem_we_n  <= 'd1;
  else if(st==ST_INPUT_SAMPLE)
    mem_we_n  <= 'd0;
  else
    mem_we_n  <= 'd1;
end
always @(posedge clk) begin
  if(!rst_n)
    mem_a <= 'd0;
  else if(st==ST_INPUT_SAMPLE)
    mem_a <= cnt;
  else if(st==ST_CHECK)
    mem_a <= 'd0;
  else if(st==ST_PARSE_SAMPLE && cnt=='d2)
    mem_a <= mem_a+'d1;
end
always @(posedge clk) begin
  if(!rst_n)
    mem_d <= 'd0;
  else if(st==ST_INPUT_SAMPLE)
    mem_d <= in_data;
end
always @(posedge clk) begin
  if(!rst_n) begin
    mem_q_x <= 'd0;
    mem_q_y <= 'd0;
  end
  else if(st==ST_PARSE_SAMPLE && cnt=='d2) begin
    mem_q_x <= mem_q[15:8];
    mem_q_y <= mem_q[7:0];
  end
end
// SYSTEM OUTPUT
reg         out_valid;
reg [15:0]  out_data;
always @(posedge clk) begin
  if(!rst_n)
    out_valid <= 'd0;
  else if(st==ST_OUTPUT)
    out_valid <= 'd1;
  else
    out_valid <= 'd0;
end
always @(posedge clk) begin
  if(!rst_n)
    out_data  <= 'd0;
  else if(st==ST_OUTPUT && cnt=='d0)
    out_data  <= {cur_x_0,cur_y_0};
  else if(st==ST_OUTPUT && cnt=='d1)
    out_data  <= {cur_x_1,cur_y_1};
  else if(st==ST_OUTPUT && cnt=='d2)
    out_data  <= {cur_x_2,cur_y_2};
  else if(st==ST_OUTPUT && cnt=='d3)
    out_data  <= {cur_x_3,cur_y_3};
  else
    out_data  <= 'd0;
end
// stopping condition for K-means
wire  stop;
assign stop = pre_x_0==cur_x_0 &&
              pre_y_0==cur_y_0 &&
              pre_x_1==cur_x_1 &&
              pre_y_1==cur_y_1 &&
              pre_x_2==cur_x_2 &&
              pre_y_2==cur_y_2 &&
              pre_x_3==cur_x_3 &&
              pre_y_3==cur_y_3;
// SYSTEM FSM
always @(posedge clk) begin
  if(!rst_n)
    st  <= ST_IDLE;
  else
    st  <= nt_st;
end
always @( * ) begin
  case(st)
    ST_IDLE: begin
      if(in_valid)
        nt_st = ST_INPUT_POINT;
      else
        nt_st = ST_IDLE;
    end
    ST_INPUT_POINT: begin
      if(cnt=='d3)
        nt_st = ST_INPUT_SAMPLE;
      else
        nt_st = ST_INPUT_POINT;
    end
    ST_INPUT_SAMPLE: begin
      if(cnt=='d4095)
        nt_st = ST_CHECK;
      else
        nt_st = ST_INPUT_SAMPLE;
    end
    ST_CHECK: begin
      if(stop)
        nt_st = ST_OUTPUT;
      else
        nt_st = ST_PARSE_SAMPLE;
    end
    ST_PARSE_SAMPLE: begin
      if(cnt=='d2)
        nt_st = ST_FIND_MIN;
      else
        nt_st = ST_PARSE_SAMPLE;
    end
    ST_FIND_MIN: begin
      if(cnt=='d4 && mem_a=='d4095)
        nt_st = ST_UPDATE;
      else if(cnt=='d4)
        nt_st = ST_PARSE_SAMPLE;
      else
        nt_st = ST_FIND_MIN;
    end
    ST_UPDATE: begin
      nt_st = ST_CHECK;
    end
    ST_OUTPUT: begin
      if(cnt=='d3)
        nt_st = ST_IDLE;
      else
        nt_st = ST_OUTPUT;
    end
    default: begin
      nt_st = ST_IDLE;
    end
  endcase
end
// memory
wire        mem_we_n_tmp;
wire[11:0]  mem_a_tmp;
wire[15:0]  mem_d_tmp;
assign  mem_we_n_tmp  = (!rst_n)? 'd0:mem_we_n;
assign  mem_a_tmp     = (!rst_n)? 'd0:mem_a;
assign  mem_d_tmp     = (!rst_n)? 'd0:mem_d;

SHAB90_4096X16X1CM16 u_SHAB90_4096X16X1CM16(
  .DO   (mem_q),
  .CK   (clk),
  .CS   (1'd1),
  .WEB  (mem_we_n_tmp),
  .A    (mem_a_tmp),
  .DI   (mem_d_tmp),
  .OE   (1'd1)
);
// SAD
SAD u_sad(
  .p1_x (mem_q_x),
  .p1_y (mem_q_y),
  .p2_x (p_x),
  .p2_y (p_y),
  .ans  (ans)
);
endmodule 