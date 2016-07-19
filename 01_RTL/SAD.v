module SAD(
  input   [7:0] p1_x,
  input   [7:0] p1_y,
  input   [7:0] p2_x,
  input   [7:0] p2_y,
  output  [8:0] ans
);
wire [7:0]  ad_x,ad_y;
assign ad_x = (p1_x>p2_x)? (p1_x-p2_x):(p2_x-p1_x);
assign ad_y = (p1_y>p2_y)? (p1_y-p2_y):(p2_y-p1_y);
assign ans  = ad_x+ad_y;
endmodule 