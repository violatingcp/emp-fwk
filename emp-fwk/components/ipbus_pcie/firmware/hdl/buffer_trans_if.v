`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:    TIFR
// Engineer:   Raghunadnan Shukla
// Module Name: buffer_trans_if
//
/////////////////////////////////////////////////////////////////////////////////

module buffer_trans_if #
       (
           parameter C_M_AXI_DATA_WIDTH = 64
       )
       (

           input user_clk,
           input ipb_clk,
           input sys_rst_n,

           input h2c0_dsc_done,

           input [10:0] ram_wr_addr,
           input [C_M_AXI_DATA_WIDTH-1:0] ram_wr_data,
           input ram_wr_en,
           input ram_wr_we,

           input ram_rd_en,
           input [10:0] ram_rd_addr,
           output  [C_M_AXI_DATA_WIDTH-1:0] ram_rd_data,

           // Transactor interface

           // trans_in
           output        trans_in_pkt_rdy,
           output [31:0] trans_in_rdata,
           output        trans_in_busy,

           // trans_out
           input [11:0] trans_out_raddr,
           input trans_out_pkt_done,
           input trans_out_we,
           input [11:0] trans_out_waddr,
           input [31:0] trans_out_wdata,

           input ipb_req,
           output ipb_rst
       );



// wire ipb_clk;
// wire user_clk;
// wire sys_rst_n;
// wire ipb_rst;
// wire ipb_req;

wire ipb_pkt_done;
wire ipb_pkt_done_pcieclk;
wire ipb_pkt_rdy;
//wire ipb_pkt_rdy_pcieclk;

wire [31:0] tran_rdata;
wire [12:0] trans_raddr;
wire trans_we;
wire [12:0] trans_waddr;
wire [31:0] trans_wdata;
wire [12:0] bram_addr_a;
wire [12:0] bram_addr_b;

reg [1:0] state;
reg ipb_pkt_rdy_pcieclk;

// interface width =64 bit, depth = 1024; simple dual port, native interface
blk_mem_gen_2 bram_transactor_in (
                  .clka(user_clk),    // input wire clka
                  .ena(ram_wr_en),      // input wire ena
                  .wea(ram_wr_we),      // input wire [0 : 0] wea
                  .addra(ram_wr_addr[9:0]),  // input wire [9 : 0] addra
                  .dina(ram_wr_data[C_M_AXI_DATA_WIDTH-1:0]),    // input wire [63 : 0] dina

                  .clkb(ipb_clk),    // input wire clkb
                  .addrb(trans_out_raddr),  // input wire [9 : 0] addrb
                  .doutb(trans_in_rdata)  // output wire [63 : 0] doutb
              );

// replace this with tx_buffer module

//    blk_mem_gen_3 bram_transactor_out (
//      .clka(ipb_clk),        // input wire clka
//      .ena(1'b1),            // input wire ena
//      .wea(trans_out_we),        // input wire [0 : 0] wea
//      .addra(trans_out_waddr),   // input wire [10 : 0] addra
//      .dina(trans_out_wdata),    // input wire [31 : 0] dina

//      .clkb(user_clk),    // input wire clkb
//      .enb(ram_rd_en),      // input wire enb
//      .addrb(ram_rd_addr[9:0]),  // input wire [9 : 0] addrb
//      .doutb(ram_rd_data[C_M_AXI_DATA_WIDTH-1:0])  // output wire [63 : 0] doutb
//    );


tx_dpram bram_transactor_out(
             .ipb_rst(ipb_rst),
             .wdata(trans_out_wdata),
             .rdata(ram_rd_data[C_M_AXI_DATA_WIDTH-1:0]),
             .we(trans_out_we),
             .rd_en(ram_rd_en),
             .waddr(trans_out_waddr),
             .raddr(ram_rd_addr[9:0]),
             .ipb_pkt_done(trans_out_pkt_done),
             .ipb_clk(ipb_clk),
             .user_clk(user_clk)
         );


ClockDomainCross signal_cross(
                     .pcie_clk (user_clk),
                     .ipb_clk(ipb_clk),

                     .ipb_pkt_rdy_pcieclk_i (ipb_pkt_rdy_pcieclk),
                     .ipb_pkt_rdy_ipbclk_o (trans_in_pkt_rdy),

                     .ipb_pkt_done_ipbclk_i (trans_out_pkt_done),
                     .ipb_pkt_done_pcieclk_o (ipb_pkt_done_pcieclk),

                     .oob_in_busy_pcieclk_i(),
                     .oob_in_busy_ipbclk_o(),

                     .ipb_req_ipbclk_i (ipb_req),
                     .ipb_req_pcieclk_o(ipb_req_pcieclk),

                     .rst_pcieclk_i (!sys_rst_n),
                     .rst_ipbclk_o (ipb_rst)

                 );


always@(posedge user_clk) begin
   if(!sys_rst_n) begin
      ipb_pkt_rdy_pcieclk <= 1'b0;
      state <= 2'b0;
   end
   else case (state)

   2'h00 : begin
              ipb_pkt_rdy_pcieclk <= 1'b0;
              if(h2c0_dsc_done) begin
                  ipb_pkt_rdy_pcieclk <= 1'b1;
                  state <= 2'h01;
              end
              else begin
                  ipb_pkt_rdy_pcieclk <= 1'b0;
                  state <= 2'h00;
              end
                       
           end
           
    2'h01: begin
             if(ipb_pkt_done_pcieclk) begin 
                 state <= 2'h00;
                 ipb_pkt_rdy_pcieclk<= 1'b0;
             end
             else
                  state <= 2'h01;
             end

    default: state<=4'h00;

    endcase
  end


endmodule
