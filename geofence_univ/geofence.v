module geofence ( clk,reset,X,Y,valid,is_inside);
  input clk;
  input reset;
  input [9:0] X;
  input [9:0] Y;
  output reg valid;
  output reg is_inside;
  //reg valid;
  //reg is_inside;

  reg [2:0] cs;
  reg [3:0] cnt;
  reg [9:0] RX_x [0:6];
  reg [9:0] RX_y [0:6];

  reg [9:0] o1_x,o1_y,o2_x,o2_y;
  reg [9:0] x1,x2,y1,y2;
  wire signed [10:0] v1_x=x1-o1_x, v2_x=x2-o2_x, v1_y=y1-o1_y, v2_y=y2-o2_y;

  parameter IDLE = 0, RX=1, SORT= 2,DET= 6,DONE=7;
  reg [2:0] i[9:0],j [9:0];

  wire signed [22:0] crs = (v1_x*v2_y) - (v2_x*v1_y);

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
          i[0]<=2;
          j[0]<=3;
          i[1]<=3;
          j[1]<=4;
          i[2]<=4;
          j[2]<=5;
          i[3]<=5;
          j[3]<=6;
          i[4]<=2;
          j[4]<=3;
          i[5]<=3;
          j[5]<=4;
          i[6]<=4;
          j[6]<=5;
          i[7]<=2;
          j[7]<=3;
          i[8]<=3;
          j[8]<=4;
          i[9]<=2;
          j[9]<=3;
        end
        DET:
        begin
          i[0]<=1;
          j[0]<=2;
          i[1]<=2;
          j[1]<=3;
          i[2]<=3;
          j[2]<=4;
          i[3]<=4;
          j[3]<=5;
          i[4]<=5;
          j[4]<=6;
          i[5]<=6;
          j[5]<=1;
        end
      endcase
    end
  end
  always @(*)
  begin
    case (cs)
      SORT:
      begin
        o1_x = RX_x[1];
        o1_y = RX_y[1];
        o2_x = RX_x[1];
        o2_y = RX_y[1];
        x1 = RX_x[i[cnt]];
        y1 = RX_y[i[cnt]];
        x2 = RX_x[j[cnt]];
        y2 = RX_y[j[cnt]];
      end
      DET:
      begin
        o1_x = RX_x[0];
        o1_y = RX_y[0];
        o2_x = RX_x[i[cnt]];
        o2_y = RX_y[i[cnt]];
        x1 = RX_x[i[cnt]];
        y1 = RX_y[i[cnt]];
        x2 = RX_x[j[cnt]];
        y2 = RX_y[j[cnt]];
      end
      default:
      begin
        o1_x = 0;
        o1_y = 0;
        o2_x = 0;
        o2_y = 0;
        x1 = 0;
        y1 = 0;
        x2 = 0;
        y2 = 0;
      end
    endcase
  end
  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      cs <= IDLE;
      cnt <= 0;
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
            cnt <= 1;
          end
        end
        RX:
        begin
          if(cnt == 6)
          begin
            cnt <= 0;
            cs <= SORT;
          end
          else
          begin
            cnt <= cnt +1;
          end
          RX_x[cnt] <= X;
          RX_y[cnt] <= Y;
        end
        SORT:
        begin
          if(crs>0)
          begin
            RX_x[j[cnt]]<=RX_x[i[cnt]];
            RX_y[j[cnt]]<=RX_y[i[cnt]];
            RX_x[i[cnt]]<=RX_x[j[cnt]];
            RX_y[i[cnt]]<=RX_y[j[cnt]];
          end

          if(cnt==9)
          begin
            cs <= DET;
            cnt <= 0;
          end
          else
          begin
            cnt <= cnt +1;
          end
        end
        DET:
        begin
          if(cnt <6)
          begin
            if(crs>0)
            begin
              cs <= DONE;
              is_inside <= 0;
              valid <= 1;
            end
            cnt <= cnt + 1;
          end
          else
          begin
            cs <= DONE;
            is_inside <= 1;
            valid <= 1;
          end
        end
        DONE:
        begin
          cs <= RX;
          cnt <= 0;
          is_inside <= 0;
          valid <= 0;
        end
      endcase
    end
  end
endmodule
