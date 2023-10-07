module TWS(
    clk,
    rst,
    SDA,
    rd_data,
    wr_data,
    wr_addr,
    rd_addr,
    wr_en,
    rd_en,
    wr_cmd,
    wr_done
  );

  input clk;
  inout SDA;
  input rst;
  input [15:0]rd_data;

output wr_done;
  output wr_en,rd_en;
  output wr_cmd;
  output reg [15:0]wr_data;
  output reg [7:0]wr_addr;
  output reg [7:0]rd_addr;


  parameter IDLE = 0, CMD =1,
            RD_ADDR = 2, RD_ADDR_DONE= 3, TWS_CTRL = 4, TWS_RDREG =5, TWS_RDREG_DONE = 6, TWS_RX = 7, TWS_RX_DONE = 8, TWM_CTRL = 9,
            WR_ADDR =10,WR_DATA=11,REQ=12;


  reg [3:0] cs;
  reg [4:0] cnt;
  always @(posedge clk ,negedge rst)
  begin
    if(!rst)
      cs <= IDLE;
    else
    begin
      case(cs)
        IDLE:
          cs <= !SDA? CMD:IDLE;
        CMD:
          cs <= SDA? WR_ADDR:RD_ADDR;
        //read
        RD_ADDR:
          cs <= cnt == 7? RD_ADDR_DONE:RD_ADDR;
        RD_ADDR_DONE:
          cs <= TWS_CTRL;
        TWS_CTRL:
          cs <= TWS_RDREG;
        TWS_RDREG:
          cs <= TWS_RDREG_DONE;
        TWS_RDREG_DONE:
          cs <= TWS_RX;
        TWS_RX:
          cs <= cnt == 15? TWS_RX_DONE:TWS_RX;
        TWS_RX_DONE:
          cs <= TWM_CTRL;
        TWM_CTRL:
          cs <= IDLE;
        //write
        WR_ADDR:
          cs <= cnt == 7? WR_DATA:WR_ADDR;
        WR_DATA:
          cs <= cnt == 15? IDLE:WR_DATA;
      endcase
    end
  end


  always @(posedge clk ,negedge rst)
  begin
    if(!rst)
      cnt <= 0;
    else if(cs == IDLE ||cs == RD_ADDR_DONE || cs == TWS_RX_DONE || (cs == WR_ADDR && cnt == 7))
      cnt <= 0;
    else if(cs == RD_ADDR||cs == TWS_RX||cs == WR_ADDR||cs == WR_DATA)
      cnt <= cnt +1;
  end

  //SDA
  reg SDA_temp;
  always @(*)
  begin
    case(cs)
      TWS_RDREG,TWS_RX_DONE:
        SDA_temp =1;
      TWS_RDREG_DONE:
        SDA_temp = 0 ;
      TWS_RX:
        SDA_temp = rd_data[cnt];
      default:
        SDA_temp = 1'bz;
    endcase
  end
  assign SDA = SDA_temp;

  always @(posedge clk ,negedge rst)
  begin
    if(!rst)
      wr_data <= 0;
    else if(cs == WR_DATA)
      wr_data <= {SDA,wr_data[15:1]};
    else if(cs == IDLE)
      wr_data <= 0;
  end

  always @(posedge clk ,negedge rst)
  begin
    if(!rst)
      wr_addr <= 0;
    else if(cs == WR_ADDR)
      wr_addr <= {SDA,wr_addr[7:1]};
    else if(cs == IDLE)
      wr_addr <= 0;
  end

  always @(posedge clk ,negedge rst)
  begin
    if(!rst)
      rd_addr <= 0;
    else if(cs == RD_ADDR)
      rd_addr <= {SDA,rd_addr[7:1]};
    else if(cs == IDLE)
      rd_addr <= 0;
  end

  assign wr_en = cs == IDLE && cnt == 16;
  assign rd_en = cs == TWS_RDREG;
  assign wr_cmd = cs == WR_ADDR && cnt == 0;
  assign wr_done = cs == IDLE;
endmodule
