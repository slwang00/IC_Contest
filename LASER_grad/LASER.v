module LASER (
    input CLK,
    input RST,
    input [3:0] X,
    input [3:0] Y,
    output reg [3:0] C1X,
    output reg [3:0] C1Y,
    output reg [3:0] C2X,
    output reg [3:0] C2Y,
    output reg DONE
  );


  parameter IDLE       = 0,
            RX         = 1,
            COMPARE    = 2,
            CHECK      = 3,
            OUTPUT     = 4;

  reg [2:0] cs;
  reg [3:0] x[0:39],y[0:39];
  reg [7:0] cnt;
  reg [1:0] cnt1;
  wire [3:0]o_x=cnt[3:0];
  wire [3:0]o_y=cnt[7:4];
  reg [3:0]old_x,old_y;
  reg [3:0]abs_x[9:0], abs_y[9:0];

  reg [9:0] c1_list[3:0], c2_list[3:0], c_list[3:0];
  reg [5:0] cvr, c2_cvr, c1_cvr, curr_cvr, curr_cvr_temp;
  reg [5:0] tot_cvr;

  integer i;
  always @(*)
  begin
    for ( i=0 ;i<10 ;i=i+1 )
    begin
      abs_x[i] = (o_x > x[i])? o_x - x[i] : x[i] - o_x;
      abs_y[i] = (o_y > y[i])? o_y - y[i] : y[i] - o_y;
      c_list[3][i] = (abs_x[i] + abs_y[i] <= 4) || (abs_x[i] == 3 && abs_y[i] == 2) || (abs_x[i] == 2 && abs_y[i] == 3);//if the condition is match,the dot is in circle
    end

    cvr = 0;
    for(i=0;i<10;i=i+1)//compute how many dot in circle 1& circle2 cover
    begin
      cvr = c2_list[0][i]? cvr : cvr + c_list[0][i];
      cvr = c2_list[1][i]? cvr : cvr + c_list[1][i];
      cvr = c2_list[2][i]? cvr : cvr + c_list[2][i];
      cvr = c2_list[3][i]? cvr : cvr + c_list[3][i];
    end

    curr_cvr = 0;
    for(i=0;i<10;i=i+1)//compute how many dot in circle1(no consider another circle)
    begin
      curr_cvr =  curr_cvr + c_list[0][i];
      curr_cvr =  curr_cvr + c_list[1][i];
      curr_cvr =  curr_cvr + c_list[2][i];
      curr_cvr =  curr_cvr + c_list[3][i];
    end
  end

  always @(posedge CLK ,posedge RST)
  begin
    if(RST)
    begin
      cs <= IDLE;
      cnt<=0;
      cnt1<=0;
      C1X<=0;
      C1Y<=0;
      C2X<=0;
      C2Y<=0;
      c1_cvr <=0;
      c2_cvr <=0;
      DONE <=0;
      tot_cvr <= 0;
      old_x <=0;
      old_y <=0;
      for ( i=0 ;i<4 ;i=i+1 )
      begin
        c1_list[i] <= 0;
        c2_list[i] <= 0;
      end
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          if(!RST)
          begin
            cs <= RX;
            {x[0],y[0]} <= {X,Y};
            cnt <= 1;
          end
        end
        RX:
        begin
          {x[0],y[0]} <= {X,Y};
          for(i=0;i<40;i=i+1)
          begin
            {x[i+1],y[i+1]}<={x[i],y[i]};
          end
          if(cnt==39)
          begin
            cs <= COMPARE;
            cnt<=0;
          end
          else
          begin
            cnt<=cnt+1;
          end
        end
        COMPARE:
        begin
          if(cnt1==3)
          begin
            cnt1 <= 0;
            if(cvr>=c1_cvr)
            begin
              c1_cvr <= cvr;//c1_cvr represents the maximum number of covers in currently considered circle
              curr_cvr_temp <= curr_cvr;
              for ( i=0 ;i<4 ;i=i+1 )
              begin
                c1_list[i] <= c_list[i];
              end
              C1X <= o_x;
              C1Y <= o_y;
            end
            if({o_y,o_x}=={4'hf,4'hf})
            begin
              cs <= CHECK;
            end
            else
            begin
              cs <= COMPARE;
              cnt <= cnt +1;
            end
          end
          else
          begin
            cnt1 <= cnt1+1;
          end

          for ( i=0 ;i<3 ;i=i+1 )
          begin
            c_list[i] <= c_list[i+1];
          end
          for ( i=0 ;i<10 ;i=i+1 )//shift reg
          begin
            {x[i],y[i]}       <= {x[i+10],y[i+10]};
            {x[i+10],y[i+10]} <= {x[i+20],y[i+20]};
            {x[i+20],y[i+20]} <= {x[i+30],y[i+30]};
            {x[i+30],y[i+30]} <= {x[i],y[i]};
          end
        end
        CHECK:
        begin
          if(old_x == C1X && old_y == C1Y)//if current position and previous postion are the same ,iteration is finsihed
          begin
            cs <= OUTPUT;
            DONE <= 1;
          end
          else
          begin
            for ( i=0 ;i<4 ;i=i+1 )
            begin
              c2_list[i] <= c1_list[i];
            end
            tot_cvr <= c2_cvr+c1_cvr;
            old_x <= C2X;
            old_y <= C2Y;
            C2X <= C1X;
            C2Y <= C1Y;
            c2_cvr <= curr_cvr_temp;
            cnt <= 0;
            c1_cvr <= 0;
            cs <= COMPARE;
          end
        end
        OUTPUT:
        begin
          tot_cvr <= 0;
          cs <= RX;
          c1_cvr <=0;
          c2_cvr <=0;
          for ( i=0 ;i<4 ;i=i+1 )
          begin
            c2_list[i] <= 0;
          end
          cnt <=0;
          DONE <= 0;
        end
      endcase
    end

  end
endmodule
