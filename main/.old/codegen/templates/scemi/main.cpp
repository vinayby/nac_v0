#include <iostream>
#include <sys/time.h>
#include <stdio.h>
#include <unistd.h>
#include "SceMiHeaders.h"
#include "Scemi.h"
#include "ALURequest.h"

int main()
{
	SceMiParameters params("scemi.params");
	SceMi* scemi(SceMi::Init(SceMi::Version(SCEMI_VERSION_STRING), &params));
	ShutdownXactor shutdown("", "scemi_shutdown", scemi);
	SceMiServiceThread* sthread = new SceMiServiceThread(scemi);
	Scemi s(scemi);

	s.outstandingReqs+=2; // NumFlits

	connect::ALURequest r;
	r.valid=1;
	r.is_tail=1;
	r.destAddr=1;
	r.vc=0;
	r.oper = 2;
	r.op1 = 5;
	r.op2 = 2;
	s.sendPacket(r);

	while(s.outstandingReqs>0){
		
	}
	shutdown.blocking_send_finish();
	sthread->stop();
	sthread->join();
	SceMi::Shutdown(scemi);
	delete sthread;

	return 0;
}

