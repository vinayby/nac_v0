/*
 * Scemi.cpp
 *
 *  Created on: 22-Sep-2015
 *      Author: dhiman
 */

#include "Scemi.h"

void getFlit_cb(void* userdata, const Flit& resp){
	CallbackData* callBack = (CallbackData*)userdata;
	(*(callBack->outstandingReqs))--;
    std::vector<uint32_t> regs;
	for (int i = resp.m_data.WORDS()-1; i>=0; i--) {
		regs.push_back(resp.m_data.getWord(i));
	}
	connect::FlitPacket flit(regs);
	uint32_t x=0;
	x = resp.m_valid;   	flit.valid = x;
	x = resp.m_is_tail; 	flit.is_tail = x;
	x = resp.m_vc; 			flit.vc = x;
	x = resp.m_destAddr;	flit.destAddr  = x;

	callBack->flits->push_back(flit.getFlits()[0]);

	if(flit.is_tail.data[0]==1){
    	std::vector<uint32_t> regs;
    	for(int i=0; i<callBack->flits->size(); i++){
    		connect::Flit f = callBack->flits->at(i);
    		std::vector<uint32_t> r = f.getRegisters();
    		for(int j=0; j<r.size(); j++){
    			regs.push_back(r[j]);

    		}
    	}
    	//printf("here ALUResult\n");
    	connect::ALUResult result(regs);
        printf("Got ALUResultPacket:%s\n",result.toString().c_str());
    }
}

Scemi::Scemi(SceMi* s){
	putFlit = new InportProxyT<Flit> ("", "scemi_putFlit_inport", s);
	getFlit = new OutportProxyT<Flit> ("", "scemi_getFlit_outport", s);
	getFlit->setCallBack(getFlit_cb, &callBack);
	outstandingReqs = 0;
	callBack.outstandingReqs = &outstandingReqs;
	callBack.flits = &flits;
}
void Scemi::sendPacket(connect::Packet packet){
	std::vector<connect::Flit> flits = packet.getFlits();
	printf("numFlits=%d\n",flits.size());
	for (unsigned int i = 0; i < flits.size(); i++) {
		connect::Flit f = flits[i];
		Flit x;
		x.m_valid = 1;
		x.m_is_tail = (i==flits.size()-1)?1:0;
		x.m_vc = packet.vc.data[0];
		x.m_destAddr = packet.destAddr.data[0];
		std::vector<uint32_t> regs = f.getRegisters();
		for (unsigned int j = 0; j < regs.size(); j++) {
			x.m_data.setWord(j, regs[j]);
		}
		std::stringstream ss;
		x.getBitString(ss);
		std::string s = ss.str();
		printf("Flit:%s\n",s.c_str());
		putFlit->sendMessage(x);
	}

}



