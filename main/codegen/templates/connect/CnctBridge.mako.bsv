<%include file='Banner.mako' args="_am=_am"/>
package CnctBridge;
import NTypes::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;
import Assert::*;

//`define NA_BRIDGE_DEBUG0 
%if _am.psn.is_connect_credit(): ##IF1
interface NOCPort;
	method ActionValue#(Flit) getFlit();
	method Action putCredits(Credit cr);

	method Action setRecvFlit(Flit flit);
	method ActionValue#(Credit) getCredits();
	method Action setRecvPortID(RecvPortId portid);
endinterface

%elif _am.psn.is_connect_peek() or _am.psn.is_fnoc_peek(): ##IF1
interface NOCPort;
	method ActionValue#(Flit) getFlit();
	method Action setNonFullVC(NF_VCMask vcmask);

	method Action setRecvFlit(Flit flit);
	method NF_VCMask getRecvVCMask();
	method Action setRecvPortID(RecvPortId portid);
endinterface

%endif ##IF1END

interface NodePort;
 interface NOCPort nocPort;
 interface LateralIOPort lateralIO;
endinterface 

interface COREPort;
	method Action put(Flit flit);
	method ActionValue#(Flit) get(); 	
endinterface

interface CnctBridge;
	interface NOCPort nocPort;
	interface Vector#(NUM_VCS, COREPort) corePort;
endinterface

%if _am.psn.is_connect_credit(): ##IF2

(* synthesize *)
(* doc = "last nac-version: ${_am.get_project_sha()[:24]}, nafile:${_am.nafile_path}" *)
module mkCnctBridge#(parameter PortId port_id)(CnctBridge);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsToNw <- replicateM(mkFIFOF);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsFromNw <- replicateM(mkSizedFIFOF(valueOf(FLIT_BUFFER_DEPTH)));
	Vector#(NUM_VCS, FIFO#(Credit)) outCreditsVCFIFO <- replicateM(mkFIFO);
	FIFO#(Flit)  sendFlitFIFO <- mkFIFO();

	FIFO#(Credit) sendCreditsFIFO <- mkFIFO;
	Reg#(RecvPortId) port_id_unused <- mkRegU;
	Vector#(NUM_VCS, Reg#(CreditCounter)) creditCounter <- replicateM(mkReg(fromInteger(valueOf(FLIT_BUFFER_DEPTH))));
	Wire#(Credit) credit_in <- mkWire;
	
  // 0 VC has highest priority
  Rules rr_creditCounter = emptyRules();
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
  let rr = (rules 
		rule r_creditCounter(flitsToNw[i].notEmpty);
			if(creditCounter[i]!=0) begin 
				let f = flitsToNw[i].first; flitsToNw[i].deq;
				sendFlitFIFO.enq(f);
				if(credit_in.valid==1 && credit_in.vc==fromInteger(i)) creditCounter[i] <= creditCounter[i];
				else creditCounter[i] <= creditCounter[i] - 1;
			end
			else if(credit_in.valid==1 && credit_in.vc==fromInteger(i)) creditCounter[i] <= creditCounter[i] + 1;
		endrule
		rule r_creditCounterEmpty(!flitsToNw[i].notEmpty);
			if(credit_in.valid==1 && credit_in.vc==fromInteger(i)) creditCounter[i] <= creditCounter[i] + 1;
      endrule
  endrules);
  rr_creditCounter = rJoinDescendingUrgency(rr_creditCounter, rr);
  end
  addRules(rr_creditCounter);
  
  // 0 VC has highest priority
  Rules rr_send_credits = emptyRules();
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
  let rr = (rules 
		rule r_send_credits;
			let f = outCreditsVCFIFO[i].first; outCreditsVCFIFO[i].deq;
			sendCreditsFIFO.enq(f);
    endrule
  endrules);
  rr_send_credits = rJoinDescendingUrgency(rr_send_credits, rr);
  end
  addRules(rr_send_credits);

	// PE Port
	Vector#(NUM_VCS, COREPort) corePortsV = newVector;
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin		
		corePortsV[i] = interface COREPort;
			method ActionValue#(Flit) get();
				let f = flitsFromNw[i].first; flitsFromNw[i].deq;
				outCreditsVCFIFO[i].enq(Credit{valid:1, vc:fromInteger(i)});
				return f;
			endmethod
			method Action put(Flit f);
				if(f.valid==1) flitsToNw[i].enq(f);
			endmethod
		endinterface;
	end
	interface corePort = corePortsV;
	// NOC Port
	interface nocPort = interface NOCPort;
		// send_port
		method ActionValue#(Flit) getFlit();
			let f = sendFlitFIFO.first; sendFlitFIFO.deq;
      //$display("Flit out ", fshow(f));
			return f;
		endmethod
		method Action putCredits(Credit cr);
			credit_in <= cr;
		endmethod
		// recv_port
		method Action setRecvFlit(Flit f);
			if(f.valid ==1) begin 
				flitsFromNw[f.vc].enq(f);
        //$display("Flit in ", fshow(f));
			end
		endmethod
		method ActionValue#(Credit) getCredits();
			let f = sendCreditsFIFO.first; sendCreditsFIFO.deq;
			return f;
		endmethod
		method Action setRecvPortID(RecvPortId portid);
		port_id_unused <= portid;
		endmethod
// // 		interface putFlitSoft = toPut(flitsToNw[0]);
// // 		interface getFlitSoft = toGet(flitsFromNw[0]);
//     interface putFlitSoft = interface Put#(Flit);
//       method Action put(Flit f);
//         corePortsV[0].put(f);
//       endmethod 
//     endinterface;
// 
//     interface getFlitSoft = interface Get#(Flit);
//     method ActionValue#(Flit) get = corePortsV[0].get;
//     endinterface;
	endinterface;
endmodule

%elif _am.psn.is_connect_peek() or _am.psn.is_fnoc_peek(): ##IF2ELSE

(* synthesize *)   
module mkCnctBridge#(parameter PortId port_id)(CnctBridge);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsToNw <- replicateM(mkFIFOF);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsFromNw <- replicateM(mkFIFOF);
	Reg#(RecvPortId) port_id_unused <- mkRegU;

	Vector#(NUM_VCS, Wire#(Bit#(1))) recv_vcmask <- replicateM(mkWire);
	FIFO#(Flit) sendFlit <- mkFIFO;
  
  Wire#(NF_VCMask) nf_vcmask <- mkWire;
	Wire#(Flit) recvFlit <- mkWire;
	
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
		rule r_recv_vcmask;
			recv_vcmask[i] <= (flitsFromNw[i].notFull?1:0);
		endrule
	end	
  
  // 0 VC has highest priority
  Rules rr_send_flit = emptyRules();
  %if _am.psn.is_fnoc_peek():
	for(Integer i=0; i<1; i=i+1) begin
%else:
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
%endif
    let rr = (rules 
      rule r_send_flit (nf_vcmask[i] == 1 && flitsToNw[i].notEmpty);
        let x = flitsToNw[i].first; flitsToNw[i].deq;
        sendFlit.enq(x);
      endrule
    endrules);
    rr_send_flit = rJoinDescendingUrgency(rr_send_flit, rr);
  end
  addRules(rr_send_flit);

  %if _am.psn.is_fnoc_peek():
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
		rule r_recv_flit((recvFlit.valid==1) /*&& (recvFlit.vc==fromInteger(i))*/); // ignore vc, read into i=0
		flitsFromNw[0].enq(recvFlit);
		endrule
	end
  %else:
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
		rule r_recv_flit((recvFlit.valid==1) && (recvFlit.vc==fromInteger(i)));
			flitsFromNw[i].enq(recvFlit);
		endrule
	end
  %endif 
	// PE Port
	Vector#(NUM_VCS, COREPort) corePortsV = newVector;
  %if _am.psn.is_fnoc_peek():
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin		
  %else:
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin		
	%endif 
		corePortsV[i] = interface COREPort;
			method ActionValue#(Flit) get();
				let f = flitsFromNw[i].first; flitsFromNw[i].deq;
`ifdef NA_BRIDGE_DEBUG0 			
  $display("port=%d CnctBridge::Flit corePort.get (from nw) called i=%d f=", port_id, i, fshow(f));  
`endif 
				return f;
			endmethod
			method Action put(Flit f);
				if(f.valid==1) flitsToNw[i].enq(f);
			endmethod
		endinterface;
	end
	interface corePort = corePortsV;

	// NOC Port
	interface nocPort = interface NOCPort;
  %if _am.psn.is_fnoc_peek():
		method ActionValue#(Flit) getFlit() if(nf_vcmask[0] == 1);
  %else:
		method ActionValue#(Flit) getFlit() if(nf_vcmask[sendFlit.first.vc] == 1);
	%endif 
			Flit f = sendFlit.first; sendFlit.deq;
      if(f.valid==1)  begin 
`ifdef NA_BRIDGE_DEBUG0 			
$display("port=%d CnctBridge::Flit out tonetwork ", port_id, fshow(f));
`endif     
    end 
			return f;
		  endmethod
		method Action setNonFullVC(NF_VCMask vcmask);
			nf_vcmask <= vcmask;
		endmethod
    method Action setRecvFlit(Flit f);
			recvFlit <= f;
			if(f.valid==1) begin 
`ifdef NA_BRIDGE_DEBUG0 			
$display("port=%d CnctBridge::Flit in fromnetwork ", port_id, fshow(f));
`endif      
			end
		endmethod
		method NF_VCMask getRecvVCMask();// if(&recv_vcmask != 0);
			NF_VCMask mask = 0;
			for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
				mask[i] = recv_vcmask[i];
			end
			return mask;
		endmethod
		method Action setRecvPortID(RecvPortId portid);// if(False);
			port_id_unused <= portid;
		endmethod
// 		//interface putFlitSoft = toPut(flitsToNw[0]);
//     //interface getFlitSoft = toGet(flitsFromNw[0]);
// 
//     interface putFlitSoft = interface Put#(Flit);
//       method Action put(Flit f);
//         corePortsV[0].put(f);
//       endmethod 
//     endinterface;
// 
//     interface getFlitSoft = interface Get#(Flit);
//       method ActionValue#(Flit) get = corePortsV[0].get;
//     endinterface;
// 
	endinterface;
endmodule
%endif ##IF2END

endpackage
## vim: ft=mako
