<%include file='Banner.mako' args="om=om"/>
package CnctBridge;
import NATypes::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;
import Assert::*;

%if om.noc_uses_credit_based_flowcontrol(): ##IF1
  
interface NOCPort;
	method ActionValue#(Flit) getFlit();
	method Action putCredits(Credit cr);

	method Action setRecvFlit(Flit flit);
	method ActionValue#(Credit) getCredits();
	method Action setRecvPortID(RecvPortId portid);
	interface Put#(Flit) putFlitSoft;
	interface Get#(Flit) getFlitSoft;
endinterface

%else: ##IF1ELSE
  
interface NOCPort;
	method ActionValue#(Flit) getFlit();
	method Action setNonFullVC(NF_VCMask vcmask);

	method Action setRecvFlit(Flit flit);
	method NF_VCMask getRecvVCMask();
	method Action setRecvPortID(RecvPortId portid);
	interface Put#(Flit) putFlitSoft;
	interface Get#(Flit) getFlitSoft;
endinterface

%endif ##IF1END

interface PEPort;
	method Action put(Flit flit);
	method ActionValue#(Flit) get(); 	
endinterface

interface CnctBridge;
	interface NOCPort nocPort;
	interface Vector#(NUM_VCS, PEPort) pePort;
endinterface

%if om.noc_uses_credit_based_flowcontrol(): ##IF2

(* synthesize *)
(* doc = "last nac-version: ${om.get_project_sha()[:24]}, nafile:${om.nafile_path}" *)
module mkCnctBridge(CnctBridge);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsToNw <- replicateM(mkFIFOF);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsFromNw <- replicateM(mkSizedFIFOF(valueOf(FLIT_BUFFER_DEPTH)));
	Vector#(NUM_VCS, FIFO#(Credit)) outCreditsVCFIFO <- replicateM(mkFIFO);
	FIFO#(Flit)  sendFlitFIFO <- mkFIFO();

	FIFO#(Credit) sendCreditsFIFO <- mkFIFO;
	Reg#(RecvPortId) port_id <- mkRegU;
	Vector#(NUM_VCS, Reg#(CreditCounter)) creditCounter <- replicateM(mkReg(fromInteger(valueOf(FLIT_BUFFER_DEPTH))));
	Wire#(Credit) credit_in <- mkWire;
	 
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
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
	end
	// 0 VC has highest priority
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
		rule r_send_credits;
			let f = outCreditsVCFIFO[i].first; outCreditsVCFIFO[i].deq;
			sendCreditsFIFO.enq(f);
		endrule
	end
	// PE Port
	Vector#(NUM_VCS, PEPort) pePortsV = newVector;
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin		
		pePortsV[i] = interface PEPort;
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
	interface pePort = pePortsV;
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
			port_id <= portid;
		endmethod
// 		interface putFlitSoft = toPut(flitsToNw[0]);
// 		interface getFlitSoft = toGet(flitsFromNw[0]);
    interface putFlitSoft = interface Put#(Flit);
      method Action put(Flit f);
        pePortsV[0].put(f);
      endmethod 
    endinterface;

    interface getFlitSoft = interface Get#(Flit);
    method ActionValue#(Flit) get = pePortsV[0].get;
    endinterface;
	endinterface;
endmodule

%else: ##IF2ELSE

(* synthesize *)   
module mkCnctBridge(CnctBridge);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsToNw <- replicateM(mkFIFOF);
	Vector#(NUM_VCS, FIFOF#(Flit)) flitsFromNw <- replicateM(mkFIFOF);
	Reg#(RecvPortId) port_id <- mkRegU;

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
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
		rule r_send_flit (nf_vcmask[i] == 1 && flitsToNw[i].notEmpty);
			let x = flitsToNw[i].first; flitsToNw[i].deq;
			sendFlit.enq(x);
		endrule
	end
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
		rule r_recv_flit((recvFlit.valid==1) && (recvFlit.vc==fromInteger(i)));
			flitsFromNw[i].enq(recvFlit);
		endrule
	end
	// PE Port
	Vector#(NUM_VCS, PEPort) pePortsV = newVector;
	for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin		
		pePortsV[i] = interface PEPort;
			method ActionValue#(Flit) get();
				let f = flitsFromNw[i].first; flitsFromNw[i].deq;
				return f;
			endmethod
			method Action put(Flit f);
				if(f.valid==1) flitsToNw[i].enq(f);
			endmethod
		endinterface;
	end
	interface pePort = pePortsV;

	// NOC Port
	interface nocPort = interface NOCPort;
		method ActionValue#(Flit) getFlit() if(nf_vcmask[sendFlit.first.vc] == 1);
			Flit f = sendFlit.first; sendFlit.deq;
      if(f.valid==1)  begin 
      //$display("Flit out ", fshow(f));
    end 
			return f;
		endmethod
		method Action setNonFullVC(NF_VCMask vcmask);
			nf_vcmask <= vcmask;
		endmethod
    method Action setRecvFlit(Flit f);
			recvFlit <= f;
			if(f.valid==1) begin 
      //$display("Flit out ", fshow(f));
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
			port_id <= portid;
		endmethod
		//interface putFlitSoft = toPut(flitsToNw[0]);
    //interface getFlitSoft = toGet(flitsFromNw[0]);

    interface putFlitSoft = interface Put#(Flit);
      method Action put(Flit f);
        pePortsV[0].put(f);
      endmethod 
    endinterface;

    interface getFlitSoft = interface Get#(Flit);
      method ActionValue#(Flit) get = pePortsV[0].get;
    endinterface;

	endinterface;
endmodule
%endif ##IF2END

endpackage
## vim: ft=mako
