import DefaultValue::*;
import SceMi::*;

import Top::*;

//`define BULK;

module [SceMiModule] mkSceMiLayer();

  SceMiClockConfiguration conf = defaultValue;   
  SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);

  TOP dut <- buildDut(mkTop, clk_port);
  Empty putFlit <- mkPutXactor(dut.putFlit, clk_port);
  Empty getFlit <- mkGetXactor(dut.getFlit, clk_port);
`ifdef BULK
  Empty putFlitBulk <- mkPutXactor(dut.putFlitBulk, clk_port);
`endif
Empty shutdown <- mkShutdownXactor();
endmodule
