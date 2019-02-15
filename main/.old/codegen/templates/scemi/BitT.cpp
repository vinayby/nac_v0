/*
 * BitT.cpp
 *
 *  Created on: 11-Sep-2015
 *      Author: kdhiman
 */

#include "BitT.h"
#include <assert.h>
#include <stdio.h>
#include <algorithm>

using namespace connect;

void BitT::setWord(uint32_t data, int wid){
	assert((wid<len) && "Illegal Word Index");
	this->data[wid] = data;
}

void BitT::setBit(bool bit, int bid){
	assert((bid<N) && "Illegal Bit Index");
	int wid = bid / 32;
	int bitid = bid % 32;
	uint32_t mask = ((bit?1:0)<<bitid);
	data[wid] |= mask;
}
std::string BitT::toString(){

	std::string outputstr="";
	for(int j=len-1; j>=0; j--){
		for(int i=31; i>=0; i--){
			outputstr += '0' + ((this->data[j] & (1<<i)) >> i);
		}
	}
	outputstr = outputstr.substr(32*len-N, N);
	//printf("%d %08x BitT=%s\n", N, data[0], outputstr.c_str());
	return outputstr;
}
void BitT::setData(std::string dat){
	int count = dat.length();
	assert((count<=N) && "Illegal Data String");
	std::string str = dat;
	uint32_t temp=0;
	int id=0;
	std::reverse(str.begin(), str.end());
	while(count>0){
		std::string word = str.substr(0, count>=32?32:count);

		for(unsigned int i=0; i<word.length(); i++){
			if(word[i]=='1') temp += (1<<i);
		}
		data[id] = temp;
		id++;
		count -= 32;
	}
}

