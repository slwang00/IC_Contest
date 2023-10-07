`timescale 1ns/10ps
module TPA(clk, reset_n,
             SCL, SDA,
             cfg_req, cfg_rdy, cfg_cmd, cfg_addr, cfg_wdata, cfg_rdata);
  input 		clk;
  input 		reset_n;
  // Two-Wire Protocol slave interface
  input 		SCL;
  inout		SDA;

  // Register Protocal Master interface
  input		cfg_req;
  output		cfg_rdy;
  input		cfg_cmd;
  input	[7:0]	cfg_addr;
  input	[15:0]	cfg_wdata;
  output	[15:0]  cfg_rdata;

  reg	[15:0] Register_Spaces	[0:255];
  reg [255:0] RIS_wr_flag;
  wire [15:0]TWS_wr_data,RIS_wr_data;
  wire  [15:0]TWS_rd_data;
  wire  [15:0]RIS_rd_data;
  wire [7:0]TWS_rd_addr,TWS_wr_addr,RIS_rd_addr,RIS_wr_addr;
  reg[1:0] wr_sel;
  reg [1:0]wr_cs;
  // ===== Coding your RTL below here =================================
  TWS t0(.clk(SCL),
         .rst(reset_n),
         .SDA(SDA),
         .rd_data(TWS_rd_data),
         .wr_data(TWS_wr_data),
         .wr_addr(TWS_wr_addr),
         .rd_addr(TWS_rd_addr),
         .wr_en(TWS_wr_en),
         .rd_en(TWS_rd_en),
         .wr_cmd(TWS_wr_cmd),
         .wr_done(TWS_wr_done));

  RIS r0(.clk(clk),
         .rst(reset_n),
         .rdy(cfg_rdy),
         .req(cfg_req),
         .cmd(cfg_cmd),
         .data_from_RIM(cfg_wdata),
         .rd_from_reg(RIS_rd_data),
         .rd_to_RIM(cfg_rdata),
         .wr_to_reg(RIS_wr_data),
         .addr(cfg_addr),
         .wr_addr(RIS_wr_addr),
         .rd_addr(RIS_rd_addr),
         .wr_en(RIS_wr_en),
         .rd_en(RIS_rd_en),
         .wr_cmd(RIS_wr_cmd),
         .wr_done(RIS_wr_done));

  integer i;
  always @(posedge clk ,negedge reset_n)
  begin
    if(!reset_n)
      for(i=0;i<256;i=i+1)
        Register_Spaces [i] <= 0;
    else if(TWS_wr_en || RIS_wr_en)
    case (wr_sel)
      2'd0 :
        Register_Spaces [TWS_wr_addr]<= TWS_wr_data;
      2'd1 :
        Register_Spaces [RIS_wr_addr]<= RIS_wr_data;
    endcase
  end

  assign  TWS_rd_data = Register_Spaces[TWS_rd_addr];
  assign  RIS_rd_data = Register_Spaces[RIS_rd_addr];
  parameter IDLE_WR = 0,TWS_WR = 1,RIS_WR = 2;

  always @(*)
  begin
    case (wr_cs)
      IDLE_WR :
        wr_sel = 2;
      TWS_WR:
        wr_sel = 0;
      RIS_WR:
        wr_sel = 1;
      default:
        wr_sel = 2;
    endcase
  end

  always @(posedge clk ,negedge reset_n)
  begin
    if(!reset_n)
      wr_cs <= IDLE_WR;
    else
    case(wr_cs)
      IDLE_WR:
      case ({TWS_wr_cmd,RIS_wr_cmd})
        2'b10:
          wr_cs <= TWS_WR;
        2'b01,2'b11:
          wr_cs <= RIS_WR;
      endcase
      TWS_WR:
      begin
        if(RIS_wr_cmd)
          wr_cs <= RIS_WR;
        else if(TWS_wr_done)
          wr_cs <= IDLE_WR;
      end
      RIS_WR:
      begin
        if(TWS_wr_cmd)
          wr_cs <= TWS_WR;
        else if(RIS_wr_done)
          wr_cs <= IDLE_WR;
      end
    endcase
  end

endmodule
