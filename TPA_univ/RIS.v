module RIS(
    clk,
    rst,
    rdy,
    req,
    cmd,
    data_from_RIM,
    rd_from_reg,
    rd_to_RIM,
    wr_to_reg,
    addr,
    wr_addr,
    rd_addr,
    wr_en,
    rd_en,
    wr_cmd,
    wr_done
  );

  input clk;
  input rst;
  input req;
  input cmd;
  input [7:0]addr;
  input [15:0] data_from_RIM;
  input [15:0] rd_from_reg;

  output  rdy;
  output wr_en,rd_en;
  output [15:0] rd_to_RIM;
  output  [15:0] wr_to_reg;
  output  [7:0]rd_addr,wr_addr;
  output wr_cmd;
  output wr_done;

  parameter IDLE = 0,CMD=1,DEC_RD=2,DEC_WR=3,RD=4,WR=5,RD_DONE=6,WR_DONE=7;

  reg [2:0] cs;
  always @(posedge clk ,negedge rst)
  begin
    if(!rst)
      cs <= IDLE;
    else
    case(cs)
      IDLE:
        cs <= req? CMD:IDLE;
      CMD:
        cs <= cmd? DEC_WR:DEC_RD;
      DEC_WR:
        cs <= WR;
      DEC_RD:
        cs <= RD;
      WR:
        cs <= WR_DONE;
      RD:
        cs <= IDLE;
      WR_DONE:
        cs <= IDLE;
    endcase
  end

  assign wr_en = cs == WR;
  assign rd_en = cs == RD;

  assign rd_addr = addr;
  assign wr_addr = addr;

  assign wr_to_reg = data_from_RIM;
  assign rdy = cs != IDLE && cs != CMD;
  assign rd_to_RIM = rd_from_reg;
  assign wr_cmd = cs == DEC_WR;
  assign wr_done = cs == WR_DONE;


endmodule
