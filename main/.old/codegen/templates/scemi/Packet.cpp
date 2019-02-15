/*
 * FlitRequest.cpp
 *
 *  Created on: 14-Sep-2015
 *      Author: kdhiman
 */

#include "Packet.h"
#include <stdlib.h>
#include <stdio.h>
#include <algorithm>
#include <assert.h>
using namespace connect;


Packet::Packet()
:
valid(W_VALID),
is_tail(W_IS_TAIL),
destAddr(W_DEST_ADDR),
vc(W_VC)
{
	fixedMembersPtr.push_back(&valid);
	fixedMembersPtr.push_back(&is_tail);
	fixedMembersPtr.push_back(&destAddr);
	fixedMembersPtr.push_back(&vc);
}
void Packet::parseRegs(std::vector<uint32_t> regs)
{
	int totalPacketSize=0;
	for(unsigned int i=0; i<fixedMembersPtr.size(); i++){
		totalPacketSize+=fixedMembersPtr[i]->N;
	}

	std::string packetStr="";
	std::string packetDataStr="";
	std::string flitStr="";

	for(unsigned int j=0; j<regs.size(); j++){
		for(int i=31; i>=0; i--){
			flitStr += '0' + ((regs[j] & (1<<i)) >> i);
		}
		//printf("Reg=%d %d\n",regs[j], regs.size());
		if((j+1)%NumRegPerFlit==0){
#if !SCEMI
			flitStr = flitStr.substr(32*NumRegPerFlit-FLIT_SIZE, FLIT_SIZE);
			packetStr = flitStr.substr(0, totalPacketSize);
			packetDataStr = flitStr.substr(totalPacketSize, FLITDATA_SIZE)+packetDataStr;
#else
			flitStr = flitStr.substr(32*NumRegPerFlit-FLITDATA_SIZE, FLITDATA_SIZE);
			packetDataStr = flitStr.substr(0, FLITDATA_SIZE)+packetDataStr;
#endif

			flitStr = "";
		}
	}
	//printf("packetDataStr %s\n",packetDataStr.c_str());
	int derivedSize=0;
	for(unsigned int i=0; i<derivedMembersPtr.size(); i++){
		derivedSize+=derivedMembersPtr[i]->N;
	}
	packetDataStr = packetDataStr.substr(packetDataStr.length()-derivedSize, derivedSize);
	totalPacketSize += derivedSize;

	packetStr += packetDataStr;
#if !SCEMI
	for(unsigned int i=0; i<fixedMembersPtr.size(); i++){
		int size = fixedMembersPtr[i]->N;
		std::string member_str = packetStr.substr(0,size);
		fixedMembersPtr[i]->setData(member_str);
		packetStr = packetStr.substr(size, packetStr.length()-size);
	}
#endif
	for(unsigned int i=0; i<derivedMembersPtr.size(); i++){
		int size = derivedMembersPtr[i]->N;
		std::string member_str = packetStr.substr(0,size);
		derivedMembersPtr[i]->setData(member_str);
		packetStr = packetStr.substr(size, packetStr.length()-size);
	}

}
std::string Packet::getDataString(){
	std::string str="";
	for(unsigned int i=0; i<derivedMembersPtr.size(); i++){
		str += derivedMembersPtr[i]->toString();
	}

	std::string temp="";
	int leftover = FLITDATA_SIZE-str.length();
	if(leftover>0){
		for(int  i=0; i<leftover; i++){
			temp += '0';
		}
	}
	str = temp+str;
	//printf("FlitDataString=%s\n",str.c_str());
	return str;
}
std::vector<Flit> Packet::getFlits(){
	std::string flitDataStr = getDataString();
	//printf("flitDataStr = %s\n",flitDataStr.c_str());
	std::vector<Flit> flits;
	int count = flitDataStr.length();;
	valid = 1;
	uint32_t tail = is_tail.data[0];
	is_tail = 0;
	int id = 0;
	std::reverse(flitDataStr.begin(), flitDataStr.end());
	while(count>0){
		if(count<=FLITDATA_SIZE) is_tail = 1;

		std::string str="";
#if !SCEMI
		for(unsigned int i=0; i<fixedMembersPtr.size(); i++){
			str += fixedMembersPtr[i]->toString();
		}
#endif
		std::string flitData = flitDataStr.substr(id*FLITDATA_SIZE, count>=FLITDATA_SIZE?FLITDATA_SIZE:count);
		std::reverse(flitData.begin(), flitData.end());
		std::string temp = "";
		int leftover = FLITDATA_SIZE-flitData.length();
		if(leftover>0){
			for(int  i=0; i<leftover; i++){
				temp += '0';
			}
		}
		flitData =temp + flitData;
		//printf("flitData %s\n",flitData.c_str());
		//printf("flit %s\n",str.c_str());

		str += flitData;
		count -= FLITDATA_SIZE;
		id++;

		//std::reverse(str.begin(), str.end());
		Flit f; f.flitStr = str;
		flits.push_back(f);
	}
	is_tail = tail;
	return flits;
}

void Packet::addMember(BitT* member){
	derivedMembersPtr.push_back(member);
}

std::vector<uint32_t> Flit::getRegisters(){
	std::vector<uint32_t> regs;
	std::string flitStr = this->flitStr;
	int count = flitStr.length();
	std::reverse(flitStr.begin(), flitStr.end());
	int id = 0;
	while(count>0){
		std::string str;
		str = flitStr.substr(id*DATA_WIDTH, count>=DATA_WIDTH?DATA_WIDTH:count);
		uint32_t temp=0;
		for (unsigned int i = 0; i < str.length(); ++i) {
			uint32_t t = (str[i] == '1')?1:0;
			t = t << i;
			temp += t;
		}
		regs.push_back(temp);
		count -= DATA_WIDTH;
		id++;
	}
	return regs;
}

/*void Packet::send(){
	std::vector<Flit> flits = getFlits();
	printf("NumFlits=%lu\n", flits.size());
	for (unsigned int i = 0; i < flits.size(); ++i) {
		//printf("FlitStr=%s\n",flits[i].flitStr.c_str());
		std::vector<uint32_t>  regs = flits[i].getRegisters();
		for (unsigned int j = 0; j < regs.size(); ++j) {
			// WRITE TO PERIPHERAL
			//BREMICS_mWriteReg(BREMICS_BASE+putFlitReadyReg*4, 0, 0);
			printf("Reg%d: %08x\n", j, regs[j]);
		}
	}
}*/
std::string Packet::toString(){
	std::string str;
	for(unsigned int i=0; i<fixedMembersPtr.size(); i++){
		str += fixedMembersPtr[i]->toString() + "_";
	}
	for(unsigned int i=0; i<derivedMembersPtr.size(); i++){
		str += derivedMembersPtr[i]->toString() + "_";
	}
	return str;
}

