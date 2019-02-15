// Harshal Kalyane

package InterFPGA;

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import Vector::*;
import Clocks :: * ;
import NTypes::*;
`define ENABLE_LED
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

typedef 32 PE_DATA_WIDTH;
typedef TDiv#(PE_DATA_WIDTH,4) NO_OF_4BIT;

typedef 32 CHECK_SEQ_WIDTH;

interface InterFPGA;
interface Put#(Bit#(PE_DATA_WIDTH)) tx;
interface Get#(Bit#(PE_DATA_WIDTH)) rx;
interface Get#(Bit#(4)) deq_serial;
interface Put#(Bit#(4)) enq_serial;
`ifdef ENABLE_LED
method Bit#(8) led ();
`endif
endinterface


(* synthesize,default_clock_osc="CLK_clkinA",default_reset="reset_A" *)
module mkInterFPGA (Bit#(3) instnum, Clock clkinB, InterFPGA ifc);
	Clock clkinA <- exposeCurrentClock;
	Reset rst <- exposeCurrentReset;
	SyncFIFOIfc#(Bit#(4)) outsyncfifo <-mkSyncFIFO(1,clkinA,rst,clkinB) ;
	FIFOF#(Bit#(PE_DATA_WIDTH)) data_enq <- mkSizedFIFOF (5);
	FIFOF#(Bit#(PE_DATA_WIDTH)) data_deq <- mkSizedFIFOF (5);
	FIFOF#(Bit#(4)) infifo <- mkSizedFIFOF (1);
	Reg#(Bit#(3)) rxstate <- mkReg(0);//0
	//Reg#(Bit#(4)) rxcount <- mkReg(0);
	Reg#(Bit#(5)) txstate <- mkReg(1);//1
	Reg#(Bit#(5)) nexttxstate <- mkReg(0);
	Reg#(Bit#(4)) rx1 <- mkReg(0);
	Reg#(Bit#(1)) sent7flag <- mkReg(0);
	Reg#(Bit#(1)) got7flag <- mkReg(0);
	Reg#(Bit#(1)) sent6flag <- mkReg(0);
	Reg#(Bit#(1)) got6flag <- mkReg(0);
	Reg#(Bit#(1)) gotproto <- mkReg(0);
	Reg#(Bit#(2)) handlproto_6 <- mkReg(0);
	Reg#(Bit#(2)) prev_handlproto_6 <- mkReg(0);
	
	Reg#(Bit#(1)) checkproto <- mkReg(0);
	Reg#(Bit#(1)) checkack <- mkReg(0);
	Reg#(Bit#(12)) got6recovery <- mkReg(0);
	Reg#(Bit#(32)) c <-mkReg(0);
	Reg#(Bit#(8)) p <-mkReg(3);
	Reg#(Bit#(8)) ptx <-mkReg(3);
	Reg#(Bit#(8)) q <-mkReg(3);
	Reg#(Bit#(8)) r <-mkReg(3);
	Reg#(Bit#(8)) s <-mkReg(3);

	Reg#(Bit#(8)) prx <-mkReg(0);
	Reg#(Bit#(8)) x <-mkReg(2);
	Reg#(Vector#(NO_OF_4BIT,Bit#(4)) ) hold_rx <-mkRegU;
	rule go;
		c<=c+1;
		
	endrule
	Reg#(Bit#(128)) test_proto <-mkReg('h312e534251a5c185945f3298b3e1);
	Reg#(Bit#(128)) check_proto_resp <-mkReg('hde4251a5c5baf8d2ba);
	//Reg#(Bit#(32)) test_proto_hand <-mkReg(32'h78594575);


	
	//(* conflict_free = "check_seq, sendata_ack_proto,sendata_proto,send7,got7dontwait" *)
	(* conflict_free = "check_seq, sendata_ack_proto,sendata_proto,send7" *)


	
	rule got7dontwait(txstate==1 && rxstate==0 && got7flag==1 && sent7flag==1 && gotproto==1 && got6flag==1);
		$display("Time:%0d C:%0d inter_fpga:%0d->  every thing ok. going to do work now!! ",$time,c,instnum);
		$display("Time:%0d C:%0d inter_fpga:%0d->  infifo_not_empty:%0d outsync_not_full:%0d ",$time,c,instnum,infifo.notEmpty(),outsyncfifo.notFull());
		$display("Time:%0d C:%0d inter_fpga:%0d->  data_enq_not_empty:%0d data_deq_not_full:%0d ",$time,c,instnum,data_enq.notEmpty(),data_deq.notFull());
			txstate<=5;
			rxstate<=5;
			
			
	endrule

	
	rule controlFSM(txstate==1 && rxstate==0 && handlproto_6==0);
	
		Bool fsend_proto =  (got6flag==0 && got7flag==0 && sent7flag==0);
		Bool fsend_ack = (gotproto==1 && got7flag==0 && sent7flag==0 );
		Bool fsend7 = (got6flag==1 && sent7flag==0 );
		$display("Time:%0d C:%0d inter_fpga:%0d-> controlFSM --------got6flag:%0d sent6flag:%0d got7flag:%0d sent7flag:%0d gotproto:%0d",$time,c,instnum,got6flag,sent6flag,got7flag,sent7flag,gotproto);
		if(fsend7)
		begin
			handlproto_6<=3;
			$display("Time:%0d C:%0d inter_fpga:%0d-> controlFSM to send7 ",$time,c,instnum);
		end
		else
		begin
			if( fsend_proto && ( !fsend_ack ||  prev_handlproto_6!=1))
			begin
				handlproto_6<=1;
				prev_handlproto_6<=1;
				$display("Time:%0d C:%0d inter_fpga:%0d-> controlFSM to sendata_proto ",$time,c,instnum);
			end
			else if( fsend_ack && ( !fsend_proto || prev_handlproto_6!=2))
			begin
				handlproto_6<=2;
				prev_handlproto_6<=2;
				$display("Time:%0d C:%0d inter_fpga:%0d-> controlFSM to sendack ",$time,c,instnum);
			end
		end
	endrule
		

	rule sendata_proto(txstate==1 && rxstate==0 && handlproto_6==1  && got6flag==0 && got7flag==0 && sent7flag==0);
		Bit#(128) temp = test_proto;
		Bit#(4) t = temp[(p):(p-3)];
		outsyncfifo.enq(temp[(p):(p-3)]);
		$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_proto --------got6flag:%0d sent6flag:%0d got7flag:%0d sent7flag:%0d gotproto:%0d",$time,c,instnum,got6flag,sent6flag,got7flag,sent7flag,gotproto);
		$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_proto p:%0d send2_proto sent:%0x",$time,c,instnum, p,t);
		if((p+4)>fromInteger(valueOf(TSub#(CHECK_SEQ_WIDTH,1))))
		begin
			p<=3;
			$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_ack_proto done state",$time,c,instnum);
			handlproto_6<=0;
			
		end
		else
		begin
			p<= p + 4;
			$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_proto staying here",$time,c,instnum);
		end
	endrule

	
	
rule check_seq(txstate==1 && rxstate==0 && (got6flag==0 || gotproto==0 || got7flag==0));
		Bit#(128) test_p = test_proto;
		Bit#(4) temp = infifo.first();	
		//$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq  -------- got temp:%0x gotproto:%0d got6flag:%0d",$time,c,instnum,temp,gotproto,got6flag);
		infifo.deq();
		$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq --------got6flag:%0d sent6flag:%0d got7flag:%0d sent7flag:%0d gotproto:%0d",$time,c,instnum,got6flag,sent6flag,got7flag,sent7flag,gotproto);
		if(temp==7) //&& sent6flag==1
		begin
			$display("Time:%0d C:%0d inter_fpga:%0d-> ***********temp:%0x ======= got temp:7 ========",$time,c,instnum,temp);
		end
		
		Bit#(4) t1 = test_p[(r):(r-3)] ;
		Bit#(4) t2 = check_proto_resp[(q):(q-3)] ;
		Bool protoflag = (temp==test_p[(r):(r-3)] && (r< fromInteger(valueOf(TSub#(CHECK_SEQ_WIDTH,1)))) );
		Bool ackflag = (temp==check_proto_resp[(q):(q-3)] && (q< fromInteger(valueOf(TSub#(CHECK_SEQ_WIDTH,1)))) );	
		if(temp!=7)
		begin
			if(protoflag && gotproto==0)
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq proto correct 4 bit  pcount:%0d data:%0x proto_data:%0x",$time,c,instnum,(r+1)/4,temp,t1);
				//txstate<=2;
				r<= r + 4;
			end
			else if(protoflag==False)
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq temp:%0x reset gotprotocol",$time,c,instnum,temp);
				r<=3;
				
			end
		
			if(ackflag && got6flag==0)
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq ack correct 4 bit  count:%0d data:%0x  ack_data:%0x",$time,c,instnum,(q+1)/4,temp,t2);
				//txstate<=2;
				q<= q + 4;
			end
			else if(ackflag==False)
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq temp:%0x reset ack",$time,c,instnum,temp);
				q<=3;
				
			end


			if(q>= fromInteger(valueOf(TSub#(CHECK_SEQ_WIDTH,1))) && got6flag==0)
			begin
			
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq Got ack!!!!!!!!!!!!!!!!",$time,c,instnum);
				got6flag<=1;
				handlproto_6<=0;
			
			end			
			else if(r>= fromInteger(valueOf(TSub#(CHECK_SEQ_WIDTH,1))) && gotproto==0)
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq Got proto!!!!!!!!!!!!!!!",$time,c,instnum);	
				gotproto<=1;
				handlproto_6<=0;
			end
				
	
		end
		else
		begin
			if(gotproto==1 || got6flag==1)
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq temp:%0x got correct Got 7 going to start",$time,c,instnum,temp);
				got7flag<=1;
				got6flag<=1;
				gotproto<=1;
				handlproto_6<=0;
			end
			else
			begin
				$display("Time:%0d C:%0d inter_fpga:%0d-> check_seq temp:%0x got wrong Got 7 going to start",$time,c,instnum,temp);
			end
		end
		
		
				
	endrule	


	rule sendata_ack_proto(txstate==1 && rxstate==0 && gotproto==1 && got7flag==0 && sent7flag==0  && handlproto_6==2);
		Bit#(128) temp = check_proto_resp;
		Bit#(4) t = temp[(s):(s-3)];
		outsyncfifo.enq(temp[(s):(s-3)]);
		$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_ack_proto --------got6flag:%0d sent6flag:%0d got7flag:%0d sent7flag:%0d gotproto:%0d",$time,c,instnum,got6flag,sent6flag,got7flag,sent7flag,gotproto);
		$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_ack_proto p:%0d sendata_ack_protosent:%0x",$time,c,instnum, s,t);
		if((s+4)>fromInteger(valueOf(TSub#(CHECK_SEQ_WIDTH,1))))
		begin
			sent6flag<=1;	
			s<=3;
			$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_ack_proto done state",$time,c,instnum);
			handlproto_6<=0;
		
			
			
		end
		else
		begin
			s<= s + 4;
			$display("Time:%0d C:%0d inter_fpga:%0d-> sendata_ack_proto staying here",$time,c,instnum);
		end
	endrule


	rule send7(txstate==1 && rxstate==0 && got6flag==1 && sent7flag==0 && handlproto_6==3 );
		$display("Time:%0d C:%0d inter_fpga:%0d->  send7 ------- sending 7 ",$time,c,instnum);
		outsyncfifo.enq(7);
		sent7flag<=1;
	endrule


//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
	//-----------------------------------------------=========================	
	rule senddata1(txstate==5);
		ptx<=3;
		if(data_enq.notEmpty())
		begin
			txstate<=6;
		end
	endrule
	
	rule sendata2(txstate==6);
		Bit#(PE_DATA_WIDTH) temp = data_enq.first();
		outsyncfifo.enq(temp[(ptx):(ptx-3)]);
		ptx<= ptx + 4;
		Bit#(4) t = temp[(ptx):(ptx-3)];
		$display("Time:%0d C:%0d inter_fpga:%0d-> sendata2 data:%0x ",$time,c,instnum,t);
		if(ptx>= fromInteger(valueOf(TSub#(PE_DATA_WIDTH,1))))
		begin
			data_enq.deq();
			txstate<=5;
		end
			
	endrule
	

	//-----------------------------------------------
	
	rule rxdata0(rxstate==5);
		prx<=0;
		if(infifo.notEmpty())
		begin
			rxstate<=6;
		end
			
	endrule
	rule rxdata1(rxstate==6);
		Bit#(4) temp = infifo.first();
		hold_rx[prx] <= temp;
		prx<= prx + 1;
		infifo.deq();
		//$display("Time:%0d C:%0d inter_fpga:%0d->  rxdata1 ",$time,c,instnum);
		if(prx>= fromInteger(valueOf(TSub#(NO_OF_4BIT,1))) )
			rxstate<=7;
	endrule
	rule rxdata2(rxstate==7);
		Bit#(PE_DATA_WIDTH) temp  = unpack(pack(hold_rx));
		data_deq.enq(temp);
		$display("Time:%0d C:%0d inter_fpga:%0d-> rxdata2 sending data:%0x tp PE ",$time,c,instnum,temp);
		rxstate<=5;
	endrule
	

	
//--------------------------------Interfaces-------------------------------------------------	
	interface tx = toPut(data_enq);
	interface rx = toGet(data_deq);
	interface deq_serial = toGet(outsyncfifo);
	//interface enq_serial = toPut(infifo);
	//interface enq_serial =
	interface Put enq_serial;
	method Action put(Bit#(4) x);
		infifo.enq(x);
	endmethod
	endinterface
`ifdef ENABLE_LED
	method Bit#(8) led();
		Bit#(8) l=0;
		l[0] = sent7flag;
		l[1] = got7flag;
		l[2] = gotproto;
		l[3] = got6flag;
		l[4] = sent6flag;
		
		l[6:5] = handlproto_6;
		return {l};
	endmethod
`endif
	/*interface MyPut mput;
		method Action put (Bit#(4) x) if(txstate==1);
		infifo.enq (x);
		endmethod
	endinterface*/


endmodule

endpackage
