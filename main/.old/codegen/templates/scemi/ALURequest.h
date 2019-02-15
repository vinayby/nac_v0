
#ifndef ALUREQUEST_H_
#define ALUREQUEST_H_

#include "Packet.h"

#define ALUREQUEST_OPER_WIDTH 2
#define ALUREQUEST_OP1_WIDTH 32
#define ALUREQUEST_OP2_WIDTH 32

namespace connect{
class ALURequest : public Packet {
public:

	BitT oper;
	BitT op1;
	BitT op2; 

	ALURequest () :

		oper(ALUREQUEST_OPER_WIDTH),
		op1(ALUREQUEST_OP1_WIDTH),
		op2(ALUREQUEST_OP2_WIDTH)

	{
		// NOTE: Order is important	

		addMember(&oper);
		addMember(&op1);
		addMember(&op2);
	}
 

	ALURequest (std::vector<uint32_t> regs) :

		oper(ALUREQUEST_OPER_WIDTH),
		op1(ALUREQUEST_OP1_WIDTH),
		op2(ALUREQUEST_OP2_WIDTH)

	{
		// NOTE: Order is important	

		addMember(&oper);
		addMember(&op1);
		addMember(&op2);
		parseRegs(regs);
	}

};
}
#endif /* ALUREQUEST_H_ */

