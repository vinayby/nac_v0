/*
 * Scemi.h
 *
 *  Created on: 22-Sep-2015
 *      Author: dhiman
 */

#ifndef SCEMI_H_
#define SCEMI_H_
#include "Packet.h"
#include "FlitPacket.h"
#include "SceMiHeaders.h"

typedef struct callbackData{
	int* outstandingReqs;
	std::vector<connect::Flit> *flits;
}CallbackData;
class Scemi {
public:
	InportProxyT<Flit>* putFlit;
	OutportProxyT<Flit>* getFlit;
	int outstandingReqs;
	std::vector<connect::Flit> flits;
	CallbackData callBack;
	void sendPacket(connect::Packet packet);
	Scemi(SceMi* s);
};


#endif /* SCEMI_H_ */
