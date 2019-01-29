`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:   TIFR
// Engineer: Raghunandan Shukla
// Module Name: tx_dpram
//////////////////////////////////////////////////////////////////////////////////

module tx_dpram(
           input ipb_rst,
           input [31:0] wdata,
           output [63:0] rdata,
           input we,
           input rd_en,
           input [12:0] waddr,
           input [12:0] raddr,
           input ipb_pkt_done,
           input ipb_clk,
           input user_clk
       );

//wire [10:0] addra;
//wire we;
//wire ipb_clk;
//wire user_clk;
wire [10:0] addrb;
wire [63:0] dout;
// reg  [63:0] rdata;
// reg bank for storing header
reg [63:0] header [1:0];
reg [63:0] h_out;

blk_mem_gen_3 blk_mem_tx_32_2048_64_1024(
                  // write port
                  .clka    (ipb_clk),       // input wire clka
                  .ena     (1'b1),          // input wire ena
                  .wea     (we),            // input wire [0 : 0] wea
                  .addra   (waddr),         // input wire [10 : 0] addra
                  .dina    (wdata),           // input wire [31 : 0] dina
                  //
                  // read port
                  .clkb    (user_clk),      // input wire clkb
                  .enb     (rd_en),          // input wire enb
                  .addrb   (addrb),         // input wire [9 : 0] addrb
                  .doutb   (dout)           // output wire [63 : 0] doutb
              );


// Header structure in 32 bit words
// h[0] = no of pages in memory == 1 for single packet in flight
// h[1] = no of words per page  == 2048 for current version of f/w
// h[2] = next page to fill     == 1 for single packet in flight
// h[3] = #reply pages updated

initial begin
        header[0] <= 64'h000007FC_00000001;
        header[1] <= 64'h00000000_00000000;
        h_out     <= 64'h00000000_00000000;
    end

always@(negedge ipb_clk) begin  // data would be stable on neg edge
        if(ipb_rst) begin
                header[1] <= 64'h00;
                //header[1] <= 64'hAABBCCDD;
            end
        else if(ipb_pkt_done) begin
                header[1][63:32] <= header[1][63:32] + 32'h00000001;
            end
    end

assign addrb [10:0] = raddr[10:0] > 2 ? raddr[10:0] - 10'h02 : 0;

// to match the one clock delay of ram with header reading

always@(posedge user_clk) begin
        h_out <= header[raddr[10:0]][63:0];
    end

assign rdata [63:0] = raddr[10:0] > 2 ? dout [63:0] : h_out[63:0];

endmodule

