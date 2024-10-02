module clk_gen (input clk, input rst, input [16:0] baud, output tx_clk);
  reg t_clk = 0;
  int tx_max = 0; //count of input_clk/baud
  int tx_count = 0; //count of clk ticks elapsed
  
  always@(posedge clk) //Update tx_max
    begin
      if(rst)
        tx_max <= 0;
      else begin
        case(baud)
          4800 : begin
            tx_max <= 14'd10416;
          end
          9600 : begin
            tx_max <= 14'd5208;
          end
          14400 : begin
            tx_max <= 14'd3472;
          end
          19200 : begin
            tx_max <= 14'd2604;
          end
          38400 : begin
            tx_max <= 14'd1302;
          end
          57600 : begin
            tx_max <= 14'd868;
          end
          default: begin
            tx_max <= 14'd5208;
          end
        endcase
      end
    end
  always@(posedge clk)
    begin
      if(rst)
        begin
          tx_count <= 0;
          t_clk <= 0;
        end
      else
        begin
          if(tx_count < (tx_max/2))
            begin
              tx_count <= tx_count + 1;
            end
          else
            begin
              t_clk <= ~t_clk;
              tx_count <= 0;
            end
        end
    end
  assign tx_clk = t_clk;
endmodule

interface clk_if;
  logic clk, rst;
  logic [16:0] baud;
  logic tx_clk;
endinterface
