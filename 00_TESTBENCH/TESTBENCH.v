`timescale 1ns/10ps

//`include "PATTERN.v"
`include "PATTERN_mem.v"

`ifdef RTL
  `include "CORE.v"
`endif

`ifdef GATE
  `include "CORE_syn.v"
`endif

`ifdef POST
  `include "CHIP.v"
`endif

module TESTBENCH();
initial begin
  `ifdef GATE
    $sdf_annotate("CORE_syn.sdf",u_core);
  `endif
  `ifdef POST
    $sdf_annotate("CHIP.sdf",u_chip);
  `endif
  
  `ifdef FSDB
    $fsdbDumpfile("CHIP.fsdb");
    $fsdbDumpvars;
  `endif  
  `ifdef VCD
    $dumpfile("CHIP.vcd");
    $dumpvars;
  `endif
end

wire          clk;
wire          rst_n;
wire          in_valid;
wire  [15:0]  in_data;
wire          out_valid;
wire  [15:0]  out_data;

`ifdef MEM
PATTERN_mem u_pattern(
  clk,
  rst_n,
  in_valid,
  in_data,
  out_valid,
  out_data
);
//`else
//PATTERN u_pattern(
//  clk,
//  rst_n,
//  in_valid,
//  in_data,
//  out_valid,
//  out_data
//);  
`endif



`ifdef RTL
CORE u_core(
  clk,
  rst_n,
  in_valid,
  in_data,
  out_valid,
  out_data
);
`endif
`ifdef GATE
CORE u_core(
  clk,
  rst_n,
  in_valid,
  in_data,
  out_valid,
  out_data
);
`endif
`ifdef POST
CHIP u_chip(
  clk,
  rst_n,
  in_valid,
  in_data,
  out_valid,
  out_data
);
`endif
endmodule 