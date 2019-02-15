/*
 * FlitRequest.h
 *
 *  Created on: 14-Sep-2015
 *      Author: kdhiman
 */

#ifndef PACKET_H_
#define PACKET_H_
#include "BitT.h"
#include "defs.h"
#include <vector>
#include <stdint.h>

namespace connect{
class Flit{
public:
	std::string flitStr;
	std::vector<uint32_t> getRegisters();
};

class Packet {
	std::vector<BitT*> derivedMembersPtr;
	std::vector<BitT*> fixedMembersPtr;

	std::string getDataString();
#if !SCEMI
	const static int NumRegPerFlit = (FLIT_SIZE+31)/32;
#else
	const static int NumRegPerFlit = (FLITDATA_SIZE+31)/32;
#endif
protected:
	void parseRegs(std::vector<uint32_t> regs);
public:
	BitT valid;
	BitT is_tail;
	BitT destAddr;
	BitT vc;
	Packet();
	void addMember(BitT* member);
	std::vector<Flit> getFlits();

	//void send();
	std::string toString();
};
}
#endif /* PACKET_H_ */
