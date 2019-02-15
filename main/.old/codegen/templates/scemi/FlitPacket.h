
#ifndef FLITPACKET_H_
#define FLITPACKET_H_

#include "Packet.h"

#define FLITPACKET_DATA_WIDTH 32

namespace connect{

class FlitPacket : public Packet {
public:

	BitT data; 

	FlitPacket () :

		data(FLITPACKET_DATA_WIDTH)

	{
		// NOTE: Order is important	

		addMember(&data);
	}
 

	FlitPacket (std::vector<uint32_t> regs) :

		data(FLITPACKET_DATA_WIDTH)

	{
		// NOTE: Order is important	

		addMember(&data);
		parseRegs(regs);
	}

};
}
#endif /* FLITPACKET_H_ */

