package InterFPGA_LVDS;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import Vector::*;
import Clocks :: * ;
import NTypes::*;

typedef 32 PE_DATA_WIDTH;
typedef 32 LVDS_DW;

instance Connectable#(Get#(Flit), Put#(Bit#(PE_DATA_WIDTH))); // use generic types
    module mkConnection#(Get#(Flit) gg, Put#(Bit#(PE_DATA_WIDTH)) pp) (Empty);
        rule connect;
            let data <- gg.get();
            pp.put(pack(data));
        endrule
    endmodule
endinstance
instance Connectable#(Get#(Bit#(PE_DATA_WIDTH)), Put#(Flit));
    module mkConnection#(Get#(Bit#(PE_DATA_WIDTH)) gg, Put#(Flit) pp ) (Empty);
        rule connect;
            let data <- gg.get();
            pp.put(unpack(data));
        endrule
    endmodule
endinstance



interface MyPut;
method Action put (Bit#(4) x);
endinterface

typedef TDiv#(PE_DATA_WIDTH,4) NO_OF_4BIT;

typedef 32 CHECK_SEQ_WIDTH;

interface InterFPGA_LVDS;
interface Put#(Bit#(PE_DATA_WIDTH)) tx;
interface Get#(Bit#(PE_DATA_WIDTH)) rx;
interface Get#(Bit#(LVDS_DW)) deq_serial;
interface Put#(Bit#(LVDS_DW)) enq_serial;
endinterface


(* synthesize,default_clock_osc="CLK_clkinA",default_reset="reset_A" *)
module mkInterFPGA_LVDS (Bit#(3) instnum, Clock clkinB, Reset reset_B, InterFPGA_LVDS ifc);
	Clock clkinA <- exposeCurrentClock;
	Reset rst <- exposeCurrentReset;
	FIFOF#(Bit#(PE_DATA_WIDTH)) inout_ <- mkFIFOF;
	SyncFIFOIfc#(Bit#(PE_DATA_WIDTH)) outin_ <- mkSyncFIFO(16, clkinB, reset_B, clkinA);
  interface tx = toPut(inout_);
  interface deq_serial = toGet(inout_);
  interface enq_serial = toPut(outin_);
  interface rx = toGet(outin_);
endmodule

endpackage
