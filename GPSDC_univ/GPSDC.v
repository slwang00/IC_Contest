`timescale 1ns/10ps
module GPSDC(clk, reset_n, DEN, LON_IN, LAT_IN, COS_ADDR, COS_DATA, ASIN_ADDR, ASIN_DATA, Valid, a, D);
  input              clk;
  input              reset_n;
  input              DEN;
  input      [23:0]  LON_IN;
  input      [23:0]  LAT_IN;
  input      [95:0]  COS_DATA;
  output    reg  [6:0]   COS_ADDR;
  input      [127:0] ASIN_DATA;
  output    reg  [5:0]   ASIN_ADDR;
  output      reg        Valid;
  output     reg [39:0]  D;
  output     reg  [63:0]  a;

  parameter IDLE=0,COS=1,ASIN=3,D_CAL=5,COS_STORE = 2,ASIN_STORE =4,WAIT=6, IP = 7,a_CAL=8;

  reg[4:0]cs;
  reg [63:0] x,x1,x0,y1,y0;
  reg [7:-16] lat_a,lon_a,lat_b,lon_b;

  wire [127:0] mul;
  reg [63:0] data1,data2;

  wire [-1:-16] abs_lon = (lon_a > lon_b) ? lon_a - lon_b : lon_b - lon_a;
  wire [-1:-16] abs_lat = (lat_a > lat_b) ? lat_a - lat_b : lat_b - lat_a;

  reg [-1:-64] cos_lat_a,cos_lat_b;//(0,64)

  wire [31:0] R = 32'd12756274;
  wire [-1:-16] rad = 16'h477;//(0,16)

  reg [-1:64] a1,a2;
  /*wire [-1:-64] a1 ;//((0,16)*(0,16))**2 = (0,64)
  wire [-1:-64] a2 ;//((0,16)*(0,16))**2 = (0,64)
  wire [-1:-128] a3 = cos_lat_a * cos_lat_b;//(0,64)*(0,64)
  wire [-1:-192] a4 = a3*a2;//(0,128)*(0,64) = (0,192)
  */

 
  assign mul = data1 * data2;

  reg  [127:0] asin;
  wire [95:0] D_temp = R*asin[63:0];//(32,0)*(0,64)=(32,64)
  reg [191:0] ip_value;
  reg [4:0]pre_state;

  reg [1:0] cnt;
  reg [3:0]cnt1;
  //top fsm
  always @(posedge clk ,negedge reset_n)
  begin
    if(!reset_n)
    begin
      cs <= IDLE;
      lat_a <= 0;
      lon_a <= 0;
      COS_ADDR <=0;
      ASIN_ADDR <=0;
      cnt <= 0;
      cnt1 <= 0;
      ip_value <=0;
      data1 <= 0;
      data2 <= 0;
      pre_state <= 0;
    end
    else
    case (cs)
      IDLE:
      begin
        if(DEN)
        begin
          cs <= COS;
          lat_b <= LAT_IN;
          lon_b <= LON_IN;
          x <= {{8{1'b0}},LAT_IN,{16{1'b0}}};
          x0 <= {{8{1'b0}},LAT_IN,{16{1'b0}}};
        end
      end
      WAIT:
      begin
        Valid <= 0;
        if(DEN)
        begin
          lat_b <= LAT_IN;
          lon_b <= LON_IN;
          lat_a <= lat_b;
          lon_a <= lon_b;

          x <= {{8{1'b0}},LAT_IN,{16{1'b0}}};
          x0 <= {{8{1'b0}},LAT_IN,{16{1'b0}}};
          COS_ADDR <= 0;
          cs <= COS;
        end
      end
      COS:
      begin
        if(x < COS_DATA[95:48])
        begin
          cs <= IP;
          pre_state <= COS;
          cnt <= cnt +1;
          x1 <= COS_DATA[95:48];
          y1 <= COS_DATA[47:0];
        end
        else
        begin
          COS_ADDR <= COS_ADDR +1;
          x0 <= COS_DATA[95:48];
          y0 <= COS_DATA[47:0];
        end
      end
      IP:
      begin
        case (cnt1)
          0 :
          begin
            data1 <= x-x0;
            data2 <= y1-y0;
            ip_value <=0;
            cnt1 <= 1;
          end
          1:
          begin
            data1 <= y0;
            data2 <= x1-x0;
            ip_value <= ip_value + mul;//add ((x-x0) * (y1-y0))
            cnt1 <=2;
          end
          2:
          begin
            ip_value <= ip_value + mul;//add (y0 * (x1-x0))
            cnt1 <=3;
          end
          3:
          begin
            cnt1 <=0;
            case(pre_state)
              COS:
              begin
                cs <= COS_STORE;
                ip_value <= (ip_value<<32)/data2;
              end
              ASIN:
              begin
                cs <= ASIN_STORE;
                ip_value <= (ip_value<<64)/data2;
              end
            endcase
          end
        endcase
      end
      COS_STORE:
      begin
        cos_lat_b <= ip_value;
        cos_lat_a <= cos_lat_b;
        if(cnt == 2)
        begin
          cnt <= 1;
          cs <= a_CAL;
          cnt1 <= 0;
        end
        if(DEN)
        begin
          lat_b <= LAT_IN;
          lon_b <= LON_IN;
          lat_a <= lat_b;
          lon_a <= lon_b;

          x <= {{8{1'b0}},LAT_IN,{16{1'b0}}};
          COS_ADDR <= 0;
          cs <= COS;
        end
      end
      a_CAL:
      begin
        case (cnt1)
          0 :
          begin
            data1 <= abs_lat;
            data2 <= rad;
            a <=0;
            cnt1 <= 1;
          end
          1:
          begin
            data1 <= mul>>1;
            data2 <= mul>>1;
            cnt1 <=2;
          end
          2:
          begin
            a1 <= mul;
            data1 <= abs_lon;
            data2 <= rad;
            cnt1 <=3;
          end
          3:
          begin
            data1 <= mul>>1;
            data2 <= mul>>1;
            cnt1 <=4;
          end
          4:
          begin
            a2 <= mul;
            data1 <= cos_lat_a;
            data2 <= cos_lat_b;
            cnt1 <=5;
          end
          5:
          begin
            data1 <= mul[127-:64];
            data2 <= a2;
            //(0,64) * (0,64) = (0,128),(cos a * cos b)位數很大，所以我捨去了小數64位之後的位數，偷吃步
            cnt1 <=6;
          end
          6:
          begin
            a <= mul[127-:64] + a1;
            cnt1 <=0;
            cs <= ASIN;
          end
        endcase
      end
      ASIN:
      begin
        x <= a;
        if(a < ASIN_DATA[127:64])
        begin
          cs <= IP;
          pre_state <= ASIN;
          x1 <= ASIN_DATA[127:64];
          y1 <= ASIN_DATA[63:0];
        end
        else
        begin
          ASIN_ADDR <= ASIN_ADDR +1;
          x0 <= ASIN_DATA[127:64];
          y0 <= ASIN_DATA[63:0];
        end
      end
      ASIN_STORE:
      begin
        asin <= ip_value[64+:64];
        ASIN_ADDR <= 0;
        cs <= D_CAL;
      end
      D_CAL:
      begin
        D <= D_temp[32+:40];
        Valid <= 1;
        cs <= WAIT;
      end
    endcase
  end

endmodule
