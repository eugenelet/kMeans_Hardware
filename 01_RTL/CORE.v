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
output              out_valid;
output      [15:0]  out_data;

kMeans n_kMeans(
  .clk        (clk),
  .rst_n      (rst_n),
  .in_valid   (in_valid),
  .in_data    (in_data),
  .out_valid  (out_valid),
  .out_data   (out_data)
);


endmodule 