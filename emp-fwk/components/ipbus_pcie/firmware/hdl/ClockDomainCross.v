`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:   TIFR
// Engineer:  Raghunandan Shukla
// Module Name: ClockDomainCross
//
//////////////////////////////////////////////////////////////////////////////////


module ClockDomainCross(
           input pcie_clk,
           input ipb_clk,

           input ipb_pkt_rdy_pcieclk_i,
           output ipb_pkt_rdy_ipbclk_o,

           input  ipb_pkt_done_ipbclk_i,
           output ipb_pkt_done_pcieclk_o,

           input oob_in_busy_pcieclk_i,
           output oob_in_busy_ipbclk_o,

           input  ipb_req_ipbclk_i,
           output ipb_req_pcieclk_o,

           input  rst_pcieclk_i,
           output rst_ipbclk_o

       );

// Local Registers
reg  [1:0] ipb_pkt_rdy_cross;
reg  [1:0] ipb_pkt_done_cross;
reg  [1:0] oob_in_busy_cross;
reg  [1:0] ipb_req_cross;
reg  [1:0] ipb_rst_cross;

wire clk = pcie_clk;



//clock domain crossing
always @(posedge ipb_clk) ipb_pkt_rdy_cross[0] <= ipb_pkt_rdy_pcieclk_i;
always @(posedge ipb_clk) ipb_pkt_rdy_cross[1] <= ipb_pkt_rdy_cross[0];

assign ipb_pkt_rdy_ipbclk_o = ipb_pkt_rdy_cross[1];

always @(posedge clk) ipb_pkt_done_cross[0] <= ipb_pkt_done_ipbclk_i;
always @(posedge clk) ipb_pkt_done_cross[1] <= ipb_pkt_done_cross[0];

assign ipb_pkt_done_pcieclk_o = ipb_pkt_done_cross[1];

always @(posedge ipb_clk) oob_in_busy_cross[0] <= oob_in_busy_pcieclk_i;
always @(posedge ipb_clk) oob_in_busy_cross[1] <= oob_in_busy_cross[0];

assign oob_in_busy_ipbclk_o = oob_in_busy_cross[1];

// ipb_req
always @(posedge clk) ipb_req_cross[0] <= ipb_req_ipbclk_i;
always @(posedge clk) ipb_req_cross[1] <= ipb_req_cross[0];

assign ipb_req_pcieclk_o = ipb_req_cross[1];

// ipb_rst
always @(posedge ipb_clk) ipb_rst_cross[0] <= rst_pcieclk_i;
always @(posedge ipb_clk) ipb_rst_cross[1] <= ipb_rst_cross[0];

assign rst_ipbclk_o = ipb_rst_cross[1];




endmodule
