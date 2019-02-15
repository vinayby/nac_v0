import DefaultValue::*;
import SceMi::*;

import Top::*;

module [SceMiModule] mkSceMiLayer();

  SceMiClockConfiguration conf = defaultValue;   
  SceMiClockPortIfc clk_port <- mkSceMiClockPort(conf);

  let dut <- buildDut(mkTop, clk_port);
  Empty putFlit <- mkPutXactor(dut.putFlit${scemi_port_id}, clk_port);
  Empty getFlit <- mkGetXactor(dut.getFlit${scemi_port_id}, clk_port);
  %if _am.enabled_lateral_data_io:
  Empty putRawData <- mkPutXactor(dut.putRawData${scemi_port_id}, clk_port);
  Empty getRawData <- mkGetXactor(dut.getRawData${scemi_port_id}, clk_port);
  %endif

  Empty shutdown <- mkShutdownXactor();
endmodule
