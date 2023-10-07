//synopsys translate_off
`include "DW_sqrt.v"
//synopsys translate_on

module geofence ( clk,reset,X,Y,R,valid,is_inside);
  input clk;
  input reset;
  input [9:0] X;
  input [9:0] Y;
  input [10:0] R;
  output reg valid;
  output reg is_inside;

  reg [2:0] cs;
  reg [3:0] cnt;
  reg [9:0] RX_x [0:5];
  reg [9:0] RX_y [0:5];
  reg [10:0] RX_r [0:5];
  reg [2:0] i[9:0],j [9:0];

  reg [9:0] o1_x,o1_y,o2_x,o2_y;
  reg signed[9:0] x1,x2,y1,y2;
  wire signed [10:0] v1_x=x1-o1_x, v2_x=x2-o2_x, v1_y=y1-o1_y, v2_y=y2-o2_y;

  parameter IDLE = 0, RX=1, SORT= 2,TOTAL_AREA = 3 , SUM_TRI_AREA = 4,DONE=5;

  wire signed [24:0] crs = (v1_x*v2_y) - (v2_x*v1_y);
  reg signed [24:0] tot_area;
  wire [19:0] tri_area;
  wire [9:0] tri_area1,tri_area2;
  reg [19:0] c_sqare;
  reg [10:0] a,b;
  wire[9:0] c,s;
  wire [19:0] sb_sc = (s-b)*(s-c);
  wire [19:0] s_sa = s*(s-a);

  DW_sqrt #(.width(20), .tc_mode(0)) c1 (.a(c_sqare), .root(c));

  DW_sqrt #(.width(20), .tc_mode(0)) tri_area11 (.a(s_sa), .root(tri_area1));
  DW_sqrt #(.width(20), .tc_mode(0)) tri_area22 (.a(sb_sc), .root(tri_area2));
  assign tri_area = tri_area1 * tri_area2;
  assign s = (a+b+c)/2;

  integer x;
  always @(*)
  begin
    if(reset)
    begin
      for(x=0;x<10;x=x+1)
      begin
        {i[x],j[x]} <=0;
      end
    end
    else
    begin
      case (cs)
        SORT:
        begin
          i[0]<=1;
          j[0]<=2;
          i[1]<=2;
          j[1]<=3;
          i[2]<=3;
          j[2]<=4;
          i[3]<=4;
          j[3]<=5;
          i[4]<=1;
          j[4]<=2;
          i[5]<=2;
          j[5]<=3;
          i[6]<=3;
          j[6]<=4;
          i[7]<=1;
          j[7]<=2;
          i[8]<=2;
          j[8]<=3;
          i[9]<=1;
          j[9]<=2;
        end
        TOTAL_AREA:
        begin
          i[0]<=0;
          j[0]<=5;
          i[1]<=5;
          j[1]<=4;
          i[2]<=4;
          j[2]<=3;
          i[3]<=3;
          j[3]<=2;
          i[4]<=2;
          j[4]<=1;
          i[5]<=1;
          j[5]<=0;
        end
      endcase
    end
  end

  always @(*)
  begin
    case (cs)
      SORT:
      begin
        x1 <= RX_x[i[cnt]];
        y1 <= RX_y[i[cnt]];
        x2 <= RX_x[j[cnt]];
        y2 <= RX_y[j[cnt]];
      end
      TOTAL_AREA:
      begin
        x1 <= RX_x[i[cnt]];
        y1 <= RX_y[i[cnt]];
        x2 <= RX_x[j[cnt]];
        y2 <= RX_y[j[cnt]];
      end
    endcase
  end
  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      cs <= IDLE;
      cnt <= 0;
      tot_area <= 0;
      a <=0;
      b <=0;
      c_sqare <=0;
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          if(!reset)
          begin
            cs <= RX;
            RX_x[0] <= X;
            RX_y[0] <= Y;
            RX_r[0] <= R;
            o1_x <= 0;
            o1_y <= 0;
            o2_x <= 0;
            o2_y <= 0;
            cnt <= 1;
          end
        end
        RX:
        begin
          if(cnt == 5)
          begin
            cnt <= 0;
            cs <= SORT;
            o1_x <= RX_x[0];
            o1_y <= RX_y[0];
            o2_x <= RX_x[0];
            o2_y <= RX_y[0];
          end
          else
          begin
            cnt <= cnt +1;
          end
          RX_x[cnt] <= X;
          RX_y[cnt] <= Y;
          RX_r[cnt] <= R;
        end
        SORT:
        begin
          if(crs>0)
          begin
            RX_x[j[cnt]]<=RX_x[i[cnt]];
            RX_y[j[cnt]]<=RX_y[i[cnt]];
            RX_r[j[cnt]]<=RX_r[i[cnt]];
            RX_x[i[cnt]]<=RX_x[j[cnt]];
            RX_y[i[cnt]]<=RX_y[j[cnt]];
            RX_r[i[cnt]]<=RX_r[j[cnt]];
          end

          if(cnt==9)
          begin
            cs <= TOTAL_AREA;
            cnt <= 0;
            o1_x <= 0;
            o1_y <= 0;
            o2_x <= 0;
            o2_y <= 0;
          end
          else
          begin
            cnt <= cnt +1;
          end
        end
        TOTAL_AREA:
        begin
          if(cnt<6)
          begin
            cnt <= cnt+1;
            tot_area <= tot_area + crs;
          end
          else
          begin
            cnt <= 0;
            cs <= SUM_TRI_AREA;
            a <=RX_r[0];
            b <=RX_r[5];
            c_sqare <= ((RX_x[0]-RX_x[5])**2)+((RX_y[0]-RX_y[5])**2);
            tot_area <= tot_area>>1;
          end
        end
        SUM_TRI_AREA:
        begin
          tot_area <= tot_area - tri_area;
          if(cnt<6)
          begin
            cnt <= cnt +1;
            a <=RX_r[cnt];
            b <=RX_r[cnt+1];
            c_sqare <= (RX_x[cnt+1]-RX_x[cnt])**2+(RX_y[cnt+1]-RX_y[cnt])**2;
          end
          else
          begin
            if(tot_area<0)
            begin
              cs <= DONE;
              cnt <= 0;
              is_inside <= 0;
              valid <= 1;
            end
            else
            begin
              cs <= DONE;
              cnt <= 0;
              is_inside <= 1;
              valid <= 1;
            end
          end
        end
        DONE:
        begin
          cs <= RX;
          cnt <= 0;
          is_inside <= 0;
          valid <= 0;
          tot_area <=0;
        end
      endcase
    end
  end
endmodule
