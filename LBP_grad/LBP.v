
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
  input   	        clk;
  input   	        reset;
  output  reg [13:0] 	gray_addr;
  output  reg        	gray_req;
  input   	        gray_ready;
  input       [7:0] 	gray_data;
  output  reg [13:0] 	lbp_addr;
  output  reg        	lbp_valid;
  output  wire [7:0] 	lbp_data;
  output  reg     	finish;

  parameter IDLE = 0,LOAD=2, DONE=3;

  reg [1:0]cs;
  reg [3:0] i;
  reg [7:0] list [0:8];
  reg [1:0] col;

  integer a;

  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      for ( a=0 ;a<9 ;a=a+1 )
      begin
        list[a] <=0;
      end
    end
    else if(cs ==LOAD&&i==9)
    begin
      for ( a=0 ;a<6 ;a=a+1 )
      begin
        list[a] <= list[a+3];
      end
    end
    else
    begin
      list[i] <= gray_data;
    end
  end

  assign lbp_data = {(list[8]>=list[4]),
                     (list[5]>=list[4]),
                     (list[2]>=list[4]),
                     (list[7]>=list[4]),
                     (list[1]>=list[4]),
                     (list[6]>=list[4]),
                     (list[3]>=list[4]),
                     (list[0]>=list[4])};

  always @(posedge clk ,posedge reset)
  begin
    if(reset)
    begin
      cs <= IDLE;
      i<=0;
      gray_addr <= 0;
      gray_req <= 0;
      lbp_addr <= 0;
      lbp_valid<=0;
      finish <= 0;
      col<=0;
    end
    else
    begin
      case (cs)
        IDLE:
        begin
          if(gray_ready)
          begin
            cs <= LOAD;
            gray_req <= 1;
          end
        end
        LOAD:
        begin
          case (i)
            0,1,3,4,6,7:
            begin
              gray_addr <= gray_addr+128;
              i<=i+1;
            end
            2,5:
            begin
              gray_addr <= gray_addr-255;
              col <= (col==2)? 2: col+1;
              i   <= (col==2)? 8: i+1;
            end
            8:
            begin
              lbp_addr <= gray_addr -129;
              lbp_valid <= 1;
              i<=9;
            end
            9:
            begin
              lbp_valid<=0;
              if(lbp_addr == 16254)
              begin
                cs <= DONE;
                finish <= 1;
              end

              gray_addr <= lbp_addr - 126;
              if(lbp_addr[6:0]==8'h7E)
              begin
                col<=0;
                i<=0;
              end
              else
              begin
                i<=6;
              end
            end
          endcase
        end
        DONE:
        begin
          cs <= DONE;
        end
      endcase
    end
  end
endmodule
