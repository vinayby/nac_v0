/*
 * BitT.h
 *
 *  Created on: 11-Sep-2015
 *      Author: kdhiman
 */

#ifndef BITT_H_
#define BITT_H_
#include <stdint.h>
#include <string>
namespace connect{
class BitT {
	int len;
public:
	uint32_t* data;//[(N==0)? 1: (N+31)/32];

	int N;
	BitT(int N){
		this->N = N;
		len = (N==0)? 1: (N+31)/32;
		data = new uint32_t[len];
	}
	void operator=(uint32_t dat){
		data[0] = dat;
	}

	void setWord(uint32_t data, int wid);
	void setBit(bool bit, int bid);
	void setData(std::string dat);
	std::string toString();

};
class Pair{
	public:
		uint32_t msw;
		uint32_t lsw;
	};
}
#endif /* BITT_H_ */
