`timescale 1ns / 10ps
module CONV (
    input  clk,
    input  reset,
    output reg busy,
    input  ready,

    output [11:0] iaddr,
    input  [19:0] idata,

    output reg cwr,
    output reg [11:0] caddr_wr,
    output [19:0] cdata_wr,

    output reg crd,
    output[11:0] caddr_rd,
    input [19:0] cdata_rd,

    output reg [2:0] csel
  );
  reg [2:0] cs;
  parameter START = 0, IDLE = 1,LAYER0 = 2, LAYER1 = 3, LAYER2 = 4, DONE = 5;

  reg [9:0] cnt;
  reg kernel_op;
  reg [11:0]caddr_rd_temp;
  wire layer0_done = caddr_wr == 4095 ;
  wire layer1_done = caddr_wr == 1023 ;
  wire layer2_done = caddr_rd_temp == 1023 ;


  wire x_l_bd = caddr_wr[5:0]== 0;
  wire x_r_bd = caddr_wr[5:0]== 63;
  wire y_u_bd = caddr_wr < 64;
  wire y_d_bd = caddr_wr >= 4032;

  wire x_bd = caddr_rd_temp[5:0] == 62;

  wire signed  [39:0] mul;
  reg signed  [39:0] cdata_wr_temp;
  reg signed [19:0] kernel;
  reg signed [19:0]idata_temp1,idata_temp2;
  reg [11:0] iaddr_offset,caddr_rd_offset;

  assign cdata_wr = cdata_wr_temp[19:0];

  always @(*)
  begin
    case (cnt)
      0:
        idata_temp1 <= idata;
      1:
        idata_temp1 <= x_l_bd || y_u_bd ? 0 : idata;
      2:
        idata_temp1 <= y_u_bd ? 0:idata;
      3:
        idata_temp1 <= x_r_bd || y_u_bd ? 0 : idata;
      4:
        idata_temp1 <= x_l_bd? 0 : idata;
      5:
        idata_temp1 <= x_r_bd? 0 : idata;
      6:
        idata_temp1 <= x_l_bd || y_d_bd ? 0 : idata;
      7:
        idata_temp1 <= y_d_bd ? 0:idata;
      8:
        idata_temp1 <= x_r_bd || y_d_bd ? 0 : idata;
      9:
        idata_temp1 <= 20'h10000;
      default:
        idata_temp1 <= 20'h0;
    endcase
  end
  assign mul = idata_temp2*kernel;

  //kernel_value
  always @(*)
  begin
    case (cnt)
      1:
        kernel = kernel_op ? 20'h02F20:20'hF8F71;
      2:
        kernel = kernel_op ? 20'hFDB55:20'h0A89E;
      3:
        kernel = kernel_op ? 20'h02992:20'h092D5;
      4:
        kernel = kernel_op ? 20'hFC994:20'h06D43;
      5:
        kernel = kernel_op ? 20'h050FD:20'h01004;
      6:
        kernel = kernel_op ? 20'h0202D:20'hF6E54;
      7:
        kernel = kernel_op ? 20'h03BD7:20'hFA6D7;
      8:
        kernel = kernel_op ? 20'hFD369:20'hFC834;
      9:
        kernel = kernel_op ? 20'h05E68:20'hFAC19;
      default:
        kernel = 20'h0;
    endcase
  end

  always @(*)
  begin
    case (cnt)
      0:
        iaddr_offset = 0;
      1:
        iaddr_offset = - 65;
      2:
        iaddr_offset = - 64;
      3:
        iaddr_offset = - 63;
      4:
        iaddr_offset = - 1;
      5:
        iaddr_offset = + 1;
      6:
        iaddr_offset = + 63;
      7:
        iaddr_offset = + 64;
      8:
        iaddr_offset = + 65;
      9:
        iaddr_offset = 0;
      default:
        iaddr_offset = 0;
    endcase
  end
  assign iaddr = caddr_wr + iaddr_offset;

  always @(*)
  begin
    case (cs)
      LAYER1:
      case (cnt)
        1:
          caddr_rd_offset =  0;
        2:
          caddr_rd_offset =  + 1;
        3:
          caddr_rd_offset =  + 64;
        4:
          caddr_rd_offset =  + 65;
        default:
          caddr_rd_offset =  0;
      endcase
      LAYER2:
        caddr_rd_offset = 0;
      default:
        caddr_rd_offset = 0;
    endcase
  end
  assign caddr_rd = caddr_rd_temp + caddr_rd_offset;

  always @(posedge clk, posedge reset)
  begin
    if (reset)
      cs <= START;
    else
    case (cs)
      START:
      begin
        cs <= !reset ? IDLE : START;
        cwr <=0;
        crd <=1;
        caddr_wr <=0;
        csel <=0;
        kernel_op <= 0;
        cdata_wr_temp <= 0;
        caddr_rd_temp <=0;
        idata_temp2 <= 0;
        cnt <=0;
        busy <=0;
      end
      IDLE:
      begin
        cs <= ready? LAYER0 : IDLE;
        busy <= 1;
      end
      LAYER0:
      begin
        cs <= cnt == 12? (kernel_op? LAYER1:LAYER0): LAYER0;
        case (cnt)
          0:
          begin//offset at begining
            idata_temp2 <= idata_temp1;
            cdata_wr_temp <= kernel_op? 40'hFF72950000:40'h0013100000;
            cnt <= 1;
          end
          default://Convolution
          begin
            idata_temp2 <= idata_temp1;
            cdata_wr_temp <= cdata_wr_temp + mul;
            cnt <= cnt +1;
          end
          10://ReLu
          begin
            cdata_wr_temp <= (cdata_wr_temp[39] || !(|cdata_wr_temp)) ? 0 : round(cdata_wr_temp);
            cwr <= 1;
            csel <= kernel_op? 3'b010:3'b001;
            cnt <= 11;
          end
          11:
          begin
            caddr_wr <=  caddr_wr+1;
            cdata_wr_temp <= 0;
            cwr <=0;
            cnt <=(layer0_done)? 12:0;
          end
          12:
          begin
            caddr_wr <=  0;
            kernel_op <= ~kernel_op;
            cnt <= 0;
          end
        endcase
      end
      LAYER1:
      begin
        cs <= cnt==7? (kernel_op ? LAYER2 : LAYER1): LAYER1;
        case (cnt)
          0:
          begin
            cdata_wr_temp <= 0;
            cwr <= 0;
            crd <= 1;
            csel <= (kernel_op)?2:1;//rd layer0
            cnt <= 1;
          end
          default:
          begin
            cdata_wr_temp <= cdata_rd>cdata_wr_temp? cdata_rd:cdata_wr_temp;
            cnt <= cnt + 1;
          end
          5:
          begin
            csel <= (kernel_op)? 4:3;
            cwr <=1;//wr layer1
            crd <=0;
            cnt <=6;
          end
          6:
          begin
            caddr_rd_temp <= (x_bd)? caddr_rd_temp+66 :caddr_rd_temp + 2;
            caddr_wr <= caddr_wr +1;
            cdata_wr_temp <= 0;
            csel <= (kernel_op)? 2:1;
            crd <=1;
            cwr <=0;
            cnt <=(layer1_done)?7:1;
          end
          7:
          begin
            crd <=0;
            caddr_wr <=0;
            caddr_rd_temp <=0;
            cnt <=0;
            kernel_op <= ~kernel_op;
          end
        endcase
      end
      LAYER2:
      begin
        cs <= cnt ==3 ? (kernel_op? DONE:LAYER2) : LAYER2;
        case (cnt)
          0://
          begin
            caddr_wr <= kernel_op;//initial address
            caddr_rd_temp <= 0;
            crd <= 1;
            cwr <= 0;
            csel <= (kernel_op)? 4:3;
            cnt <= 1;
          end
          1://RD
          begin
            cwr <= 1;
            crd <= 0;
            csel <= 5;
            cdata_wr_temp <= cdata_rd;
            cnt <= 2;
          end
          2://WR
          begin
            caddr_rd_temp <= caddr_rd_temp + 1;
            caddr_wr <= caddr_wr + 2;
            crd <= 1;
            cwr <= 0;
            csel <= (kernel_op)? 4:3;
            cnt <= (layer2_done)? 3:1;
          end
          3://LAYER2 DONE
          begin
            kernel_op <= ~kernel_op;
            caddr_wr <=0;
            caddr_rd_temp <=0;
            cdata_wr_temp <= 0;
            cnt <= 0;
          end
        endcase
      end
      DONE:
      begin
        cs <= DONE;
        busy <=0;
      end
    endcase
  end

  function [19:0]round;
    input  [39:0]in ;

    reg  caary_bit;
    reg [39:0]round_temp;
    begin
      round = in[35:16] + in[15];
    end

  endfunction

endmodule
