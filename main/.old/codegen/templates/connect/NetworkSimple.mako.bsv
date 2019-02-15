package NetworkSimple;
import NATypes::*;
import Vector::*;

	(* always_ready *)
interface SendPort;
	method Action putFlit(Flit flit_in);
	method ActionValue#(NF_VCMask) getNonFullVCs();
endinterface
	(* always_ready *)
interface RecvPort;
	method ActionValue#(Flit) getFlit();
	method Action putNonFullVCs(NF_VCMask nonFullVCs);
endinterface
	(* always_ready *)
interface RecvInfo;
	method RecvPortId getRecvPortID();
endinterface

interface NetworkSimpleIfc;
	interface Vector#(NUM_USER_SEND_PORTS, SendPort) send_ports;
	interface Vector#(NUM_USER_RECV_PORTS, RecvPort) recv_ports;
	interface Vector#(NUM_USER_RECV_PORTS, RecvInfo) recv_ports_info;
endinterface

(* synthesize *)   
module mkNetworkSimple(NetworkSimpleIfc);
	//  EMPTY :: to be replaced by correspondind .v files at compile time
endmodule
endpackage

