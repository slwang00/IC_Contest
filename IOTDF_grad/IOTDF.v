`timescale 1ns/10ps
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
  input          clk;
  input          rst;
  input          in_en;
  input  [7:0]   iot_in;
  input  [2:0]   fn_sel;
  output  reg    busy;
  output   reg      valid;
  output reg [127:0] iot_out;

  parameter IDLE = 0,OUTPUT=8,LOAD=9;
  parameter MAX = 3'd1,MIN=3'd2,AVG=3'd3,EXT=3'd4,EXC=3'd5,PMAX=3'd6,PMIN=3'd7;
  parameter EXT_LOW = 128'h6FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
  parameter EXT_HIGH = 128'hAFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
  parameter EXC_LOW = 128'h7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
  parameter EXC_HIGH = 128'hBFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
  reg [3:0] cs ;
  reg [7:0]temp1[15:0],temp3[15:0];
  reg [4:0] i,j;
  reg [127:0]temp1_w,temp3_w;
  reg first_round;
  reg [2:0]carry;
  integer a;

  always @(*)
  begin
    for (a = 0;a<=15 ;a=a+1 )
    begin
      temp1_w[(a<<3)+:8]=temp1[a];
      temp3_w[(a<<3)+:8]=temp3[a];
    end
  end

  reg[134:0] add_res;

  always @(posedge clk ,posedge rst)
  begin
    if(rst)
    begin
      busy <=0;
      valid<=0;
      cs<=IDLE;
      iot_out<=0;
      i<=0;
      j<=0;
      first_round<=0;
      case (fn_sel)
        MAX,PMAX:
          iot_out<=0;
        MIN,PMIN:
          iot_out<={128{1'b1}};
        default:
          iot_out<=0;
      endcase
      for (a = 0;a<=15 ;a=a+1 )
      begin
        temp1[a]<=0;
        temp3[a]<=0;
      end
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          if(!rst)
          begin
            cs <= LOAD;
            add_res <= 0;
          end
        end
        LOAD:
        begin
          busy<=(i>=14);
          valid<=0;
          cs<=(i==15)?fn_sel:LOAD;
          i<=in_en? i+1:i;
          temp1[0]<=iot_in;
          for (a = 1;a<=15 ;a=a+1 )
          begin
            temp1[a]<=temp1[a-1];
          end
        end
        MAX:
        begin
          j<=j+1;
          i<=0;
          if(temp1_w>iot_out)
          begin
            iot_out<=temp1_w;
          end

          if(j==7)
          begin
            valid<=1;
            busy<=0;
            j<=0;
            cs<=OUTPUT;
          end
          else
          begin
            cs<=LOAD;
          end
        end
        MIN:
        begin
          j<=j+1;
          i<=0;
          if(temp1_w<iot_out)
          begin
            iot_out<=temp1_w;
          end

          if(j==7)
          begin
            valid<=1;
            busy<=0;
            j<=0;
            cs<=OUTPUT;
          end
          else
          begin
            cs<=LOAD;
          end
        end
        AVG:
        begin
          j<=j+1;
          i<=0;
          add_res <= add_res+temp1_w;

          if(j==7)
          begin
            cs<=OUTPUT;
          end
          else
          begin
            cs<=LOAD;
          end
        end
        EXT:
        begin
          i<=0;
          if(temp1_w>EXT_LOW && temp1_w<EXT_HIGH)
          begin
            iot_out<=temp1_w;
            valid<=1;
            cs<=OUTPUT;
          end
          else
          begin
            busy<=0;
            cs <= LOAD;
          end
        end
        EXC:
        begin
          i<=0;
          if(temp1_w<EXC_LOW || temp1_w>EXC_HIGH)
          begin
            iot_out<=temp1_w;
            valid<=1;
            cs<=OUTPUT;
          end
          else
          begin
            busy<=0;
            cs <= LOAD;
          end
        end
        PMAX:
        begin
          i<=0;
          j<=j+1;
          if(temp1_w>iot_out)
          begin
            iot_out <= temp1_w;
          end

          if(j==7)
          begin
            j<=0;
            cs<=OUTPUT;
          end
          else
          begin
            busy<=0;
            cs <= LOAD;
          end
        end
        PMIN:
        begin
          i<=0;
          j<=j+1;
          if(temp1_w<iot_out)
          begin
            iot_out <= temp1_w;
          end

          if(j==7)
          begin
            j<=0;
            cs<=OUTPUT;
          end
          else
          begin
            busy<=0;
            cs <= LOAD;
          end
        end
        OUTPUT:
        begin
          busy<=0;
          add_res<=0;
          case (fn_sel)
            MAX:
            begin
              valid<=0;
              iot_out<=0;
              cs<=LOAD;
            end
            MIN:
            begin
              valid<=0;
              iot_out<={128{1'b1}};
              cs<=LOAD;
            end
            AVG:
            begin
              valid<=1;
              busy<=0;
              j<=0;
              iot_out<=add_res>>3;
              cs<=LOAD;
            end
            EXT:
            begin
              valid<=0;
              cs<=LOAD;
            end
            EXC:
            begin
              valid<=0;
              cs<=LOAD;
            end
            PMAX:
            begin
              cs<=LOAD;
              busy<=0;
              if(iot_out>temp3_w||!first_round)
              begin
                first_round<=1;
                valid<=1;
                for (a = 0;a<=15 ;a=a+1 )
                begin
                  temp3[a]<=iot_out[(a<<3)+:8];
                end
              end
            end
            PMIN:
            begin
              cs<=LOAD;
              busy<=0;
              if(iot_out<temp3_w||!first_round)
              begin
                first_round<=1;
                valid<=1;
                for (a = 0;a<=15 ;a=a+1 )
                begin
                  temp3[a]<=iot_out[(a<<3)+:8];
                end
              end
            end
          endcase
        end
      endcase
    end

  end
endmodule
