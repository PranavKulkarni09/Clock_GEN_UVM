`include "uvm_macros.svh"
import uvm_pkg::*;
typedef enum bit [1:0] {reset_asserted = 0, random_baud = 1} oper_mode;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction)
  oper_mode oper; rand logic [16:0] baud; logic tx_clk; real period;
  constraint baud_c {baud inside{4800, 9600, 14400, 19200, 38400, 57600};};
  
  function new(string path="transaction");
    super.new(path);
  endfunction
endclass

class reset_clk extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_clk)
  
  transaction tr;
  
  function new(string path = "reset_clk");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(5)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        tr.oper = reset_asserted;
        finish_item(tr);
      end
  endtask
endclass

class variable_baud extends uvm_sequence#(transaction);
  `uvm_object_utils(variable_baud)
  
  transaction tr;
  
  function new(string path = "variable_baud");
    super.new(path);
  endfunction
  
  virtual task body();
    repeat(5)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        tr.oper = random_baud;
        finish_item(tr);
      end
  endtask
endclass

class driver extends uvm_driver#(transaction); //Assign tr ports and if ports to get data
  `uvm_component_utils(driver)
  
  transaction tr;
  virtual clk_if clkif;
  
  function new(string path = "driver", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual clk_if)::get(this,"","clkif",clkif))
      `uvm_error("DRV", "Unable to access config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(tr); //Grants the sequencer and starts to receive data
      if(tr.oper == reset_asserted)
        begin
          clkif.rst <= 1'b1;
          @(posedge clkif.clk);
        end
      else if(tr.oper == random_baud)
        begin
          `uvm_info("DRV", $sformatf("Baud: %0d", tr.baud), UVM_NONE);
          clkif.rst <= 1'b0;
          clkif.baud <= tr.baud;
          @(posedge clkif.clk);
          @(posedge clkif.tx_clk);
          @(posedge clkif.tx_clk);
        end
      seq_item_port.item_done();
    end
  endtask
endclass

class monitor extends uvm_monitor; //Sends data to scoreboard
  `uvm_component_utils(monitor)
  
  transaction tr;
  virtual clk_if clkif;
  real ton = 0;
  real toff = 0;
  uvm_analysis_port#(transaction) send;
  
  function new(string path = "monitor", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr = transaction::type_id::create("tr");
    send = new("send", this);
    if(!uvm_config_db#(virtual clk_if)::get(this,"","clkif",clkif)) //Get access of interface
      `uvm_error("MON", "Unable to access config_db");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge clkif.clk);
      if(clkif.rst)
        begin
          tr.oper = reset_asserted;
          ton = 0;
          toff = 0;
          `uvm_info("MON","System Reset", UVM_NONE);
          send.write(tr);
        end
      else
        begin
          tr.baud = clkif.baud;
          tr.oper = random_baud;
          ton = 0;
          toff = 0;
          @(posedge clkif.tx_clk);
          ton = $realtime;
          @(posedge clkif.tx_clk);
          toff = $realtime;
          tr.period = toff - ton;
          `uvm_info("MON", $sformatf("Baud: %0d | Period: %0f", tr.baud, tr.period), UVM_NONE);
          send.write(tr);
        end
    end
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  //Main logic generally goes here
  `uvm_component_utils(scoreboard)
  
  real baud_count = 0;
  real count = 0;
  uvm_analysis_imp#(transaction, scoreboard) recv;
  
  function new(string path = "scoreboard", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv = new("recv", this);
  endfunction
  
  virtual function void write(transaction tr);
    count = (tr.period)/20; //Divide by 20 cuz 50MHz
    baud_count = count;
    `uvm_info("SCO", $sformatf("Baud: %0d | Count: %0f | Baud_Count: %0f", tr.baud, count, baud_count), UVM_NONE);
    case(tr.baud)
      4800: begin
        if(baud_count == 10418)
          `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
          `uvm_error("SCO", "Test Failed");
      end
      9600: begin
        if(baud_count == 5210)
          `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
          `uvm_error("SCO", "Test Failed");
      end
      14400: begin
        if(baud_count == 3474)
          `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
          `uvm_error("SCO", "Test Failed");
      end
      19200: begin
        if(baud_count == 2606)
          `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
          `uvm_error("SCO", "Test Failed");
      end
      38400: begin
        if(baud_count == 1304)
          `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
          `uvm_error("SCO", "Test Failed");
      end
      57600: begin
        if(baud_count == 870)
          `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
          `uvm_error("SCO", "Test Failed");
      end
    endcase
  endfunction
endclass

class agent extends uvm_agent;
  //Connection of driver and sequencer
  `uvm_component_utils(agent)
  
  driver d;
  monitor m;
  uvm_sequencer#(transaction) seqr;
  
  function new(string path = "agent", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = driver::type_id::create("d", this);
    m = monitor::type_id::create("m", this);
    seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class environment extends uvm_env;
  //Connection of monitor and scoreboard
  `uvm_component_utils(environment)
  
  agent a;
  scoreboard sco;
  
  function new(string path = "environment", uvm_component c);
    super.new(path, c);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a", this);
    sco = scoreboard::type_id::create("sco", this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.m.send.connect(sco.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test)
  
  environment e;
  reset_clk rstclk;
  variable_baud varbaud;
  
  function new(string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e = environment::type_id::create("e", this);
    rstclk = reset_clk::type_id::create("rstclk", this);
    varbaud = variable_baud::type_id::create("varbaud", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    varbaud.start(e.a.seqr);
    #20;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  clk_if clkif();
  clk_gen DUT (.clk(clkif.clk), .rst(clkif.rst), .baud(clkif.baud), .tx_clk(clkif.tx_clk));
  
  initial begin
    clkif.clk <= 0;
  end
  
  always #10 clkif.clk <= ~clkif.clk;
  
  initial begin
    uvm_config_db#(virtual clk_if)::set(null,"*","clkif",clkif);
    run_test("test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
endmodule
