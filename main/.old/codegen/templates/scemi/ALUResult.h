
#ifndef ALURESULT_H_
#define ALURESULT_H_

#include "Packet.h"

#define ALURESULT_SOURCEID_WIDTH 4
#define ALURESULT_RESULT_WIDTH 32
namespace connect{
class ALUResult : public Packet {
public:

	BitT sourceId;
	BitT result; 

	ALUResult () :

		sourceId(ALURESULT_SOURCEID_WIDTH),
		result(ALURESULT_RESULT_WIDTH)

	{
		// NOTE: Order is important	

		addMember(&sourceId);
		addMember(&result);
	}
 

	ALUResult (std::vector<uint32_t> regs) :

		sourceId(ALURESULT_SOURCEID_WIDTH),
		result(ALURESULT_RESULT_WIDTH)

	{
		// NOTE: Order is important	

		addMember(&sourceId);
		addMember(&result);
		parseRegs(regs);
	}

};
}
#endif /* ALURESULT_H_ */

