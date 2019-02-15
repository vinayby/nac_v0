//
// Copyright (c) 2014, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//


package Hls_core_interfaces;
import Bluespec_def::*;
import Memory_interface::*;
import Memory_pack::*;
import Extends::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import FIFOLevel::*;
import ModuleContext::*;

`define MEM_TEST_STDIO_DEBUG_ENABLE_Z

interface HLS_CORE_IFC;
    // hls core control methods
    method Action start();
    method Bool isIdle();
    method Bool isDone();
    method Bool isReady();
    method Action setVerboseMode(Bool verbose);
endinterface

  interface HLS_AP_BUS_IFC#(numeric type t_ADDR_SZ, numeric type t_DATA_SZ);
      method Action reqNotFull();
      method Action rspNotEmpty();
      method Action readRsp( Bit#(t_DATA_SZ) resp);
      method Bit#(t_ADDR_SZ) reqAddr();
      method Bit#(t_ADDR_SZ) reqSize();
      method Bit#(t_DATA_SZ) writeData();
      method Bool writeReqEn();
  endinterface

//   interface HLS_AP_BUS_IFC#(type tpd, type tpa);
//       method Action reqNotFull();
//       method Action rspNotEmpty();
//       method Action readRsp( tpd resp);
//       method tpa reqAddr();
//       method tpa reqSize();
//       method tpd writeData();
//       method Bool writeReqEn();
//   endinterface

//
// Wrap mkMemIfcToPseudoMultiMemSyncWrites to handle the case where there is
// only one reader
//

module mkMemIfcToPseudoMultiMemSyncWritesWrapper#(MEMORY_IFC#(t_ADDR, t_DATA) mem)
    // interface:
    (MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ),
              Log#(n_READERS, n_READERS_SZ));

   MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA) multiMem;
   if (valueOf(n_READERS) == 1)
   begin
       MEMORY_MULTI_READ_IFC#(1, t_ADDR, t_DATA) multiMemWithSingleReader <- mkMemIfcToMultiMemIfc(mem);
       multiMem <- mkMultiMemSingleReaderIfcToMultiMemIfc(multiMemWithSingleReader);
       return multiMem;
   end
   else
   begin
       multiMem <- mkMemIfcToPseudoMultiMemSyncWrites(mem);
       return multiMem;
   end
endmodule

module mkMultiMemSingleReaderIfcToMultiMemIfc#(MEMORY_MULTI_READ_IFC#(1, t_ADDR, t_DATA) mem)
    // interface:
    (MEMORY_MULTI_READ_IFC#(n_READERS, t_ADDR, t_DATA))
    provisos (Bits#(t_ADDR, t_ADDR_SZ),
              Bits#(t_DATA, t_DATA_SZ));

    Vector#(n_READERS, MEMORY_READER_IFC#(t_ADDR, t_DATA)) portsLocal = newVector();
    portsLocal[0] =
        interface MEMORY_READER_IFC#(t_ADDR, t_DATA);
            method Action readReq(t_ADDR addr) = mem.readPorts[0].readReq(addr);

            method ActionValue#(t_DATA) readRsp();
                let v <- mem.readPorts[0].readRsp();
                return v;
            endmethod

            method t_DATA peek() = mem.readPorts[0].peek();
            method Bool notEmpty() = mem.readPorts[0].notEmpty();
            method Bool notFull() = mem.readPorts[0].notFull();
        endinterface;

    interface readPorts = portsLocal;

    method Action write(t_ADDR addr, t_DATA val) = mem.write(addr, val);
    method Bool writeNotFull() = mem.writeNotFull();
endmodule

`ifdef 0
module mkHlsApBusMemConnection#(MEMORY_IFC#(t_MEM_ADDR, t_MEM_DATA) mem, 
                                                   HLS_AP_BUS_IFC#(t_AP_ADDR_SZ, t_AP_DATA_SZ) bus, 
                                                   NumTypeParam#(t_MEM_DATA_SZ) containerDataSz, 
                                                   Bool verbose, 
                                                   Integer busId)
    // interface:
    ()
    provisos (Bits#(t_MEM_ADDR, t_MEM_ADDR_SZ),
              Alias#(Bit#(t_MEM_DATA_SZ), t_MEM_DATA),
            //  NumAlias#(MEM_PACK_CONTAINER_READ_PORTS#(1, t_AP_DATA_SZ, t_MEM_DATA_SZ), n_MEM_READERS),
//              NumAlias#(TSub#(TAdd#(t_MEM_ADDR_SZ, MEM_PACK_SMALLER_OBJ_IDX_SZ#((t_AP_DATA_SZ), t_MEM_DATA_SZ)),                              MEM_PACK_LARGER_OBJ_IDX_SZ#((t_AP_DATA_SZ), t_MEM_DATA_SZ)), t_USER_ADDR_SZ),
//              Alias#(Bit#(t_USER_ADDR_SZ), t_USER_ADDR),
Alias#(t_MEM_ADDR, t_USER_ADDR),
              Alias#(Bit#(t_AP_ADDR_SZ), t_AP_ADDR),
              Alias#(Bit#(t_AP_DATA_SZ), t_AP_DATA)
            );

    FIFOLevelIfc#(Tuple3#(t_MEM_ADDR, t_MEM_ADDR, Bool), 16) reqQ <- mkFIFOLevel();
    FIFOF#(t_AP_DATA) writeDataQ <- mkSizedFIFOF(8);
    Reg#(Bool) busWriteBurstPending <- mkReg(False);
    Reg#(t_AP_ADDR) burstSize <- mkReg(unpack(0));
    Reg#(t_AP_ADDR) writeDataNum <- mkReg(unpack(0));
    

    // get memory request from bus
    rule getReadReq (!bus.writeReqEn);
        reqQ.enq(tuple3(resize(bus.reqAddr), resize(bus.reqSize), False));
        $display($format("apBusGetReadReq: port=%0d, addr=0x%x, size=0x%x", busId, bus.reqAddr, bus.reqSize));
    endrule
    rule getWriteReq (bus.writeReqEn && !busWriteBurstPending);
        reqQ.enq(tuple3(resize(bus.reqAddr), resize(bus.reqSize), True));
        writeDataQ.enq(bus.writeData);
        $display($format("apBusGetWriteReq: port=%0d, addr=0x%x, size=0x%x, data=0x%x", busId, bus.reqAddr, bus.reqSize, bus.writeData));
        if (pack(bus.reqSize) > 1)
        begin
            busWriteBurstPending <= True;
            burstSize <= bus.reqSize;
            writeDataNum <= 1;
        end
    endrule
    rule getWriteBurstPendingData (bus.writeReqEn && busWriteBurstPending);
        writeDataQ.enq(bus.writeData);
        $display($format("apBusGetWriteBurstPending: port=%0d, data=0x%x", busId, bus.writeData));
        if (writeDataNum == (burstSize-1) )
        begin
            busWriteBurstPending <= False;
        end
        else
        begin
            writeDataNum <= writeDataNum+1;
        end
    endrule
    
    (* fire_when_enabled *)
    rule checkReqFull (reqQ.isLessThan(8) && writeDataQ.notFull);
        bus.reqNotFull();
    endrule

    // forward request to memory
    Reg#(Bool) reqPending <- mkReg(False);
    Reg#(t_USER_ADDR) memBurstNum <- mkReg(unpack(0));
 /*  
    //
    // May need additional read port(s) to handle data items 
    // that have different sizes from the underlying scratchpad data size
    //
    // Use mkMemIfcToPseudoMultiMemSyncWrites to create the illusion of 
    // multiple read ports by multiplexing all requests on a single physical 
    // read port.  
    // 
    MEMORY_MULTI_READ_IFC#(n_MEM_READERS, t_MEM_ADDR, t_MEM_DATA) multiPortMem <- 
        mkMemIfcToPseudoMultiMemSyncWritesWrapper(mem);
    // MEMORY_MULTI_READ_IFC#(n_MEM_READERS, t_MEM_ADDR, t_MEM_DATA) multiPortMem;
    // if (valueOf(n_MEM_READERS) == 1) 
    // begin
    //     multiPortMem <- mkMemIfcToMultiMemIfc(mem);
    // end
    // else
    // begin
    //     multiPortMem <- mkMemIfcToPseudoMultiMemSyncWrites(mem);
    // end

    MEMORY_MULTI_READ_IFC#(1, t_USER_ADDR, t_AP_DATA) pack_mem_multi;
    MEMORY_IFC#(t_USER_ADDR, t_AP_DATA) pack_mem;
    if (valueOf(t_USER_ADDR_SZ) == valueOf(t_MEM_ADDR_SZ))
    begin
        // One object per container
        pack_mem_multi <- mkMemPack1To1(containerDataSz, multiPortMem);
        pack_mem <- mkMultiMemIfcToMemIfc(pack_mem_multi);
    end
    else if (valueOf(t_USER_ADDR_SZ) > valueOf(t_MEM_ADDR_SZ))
    begin
        // Multiple objects per container
        // pack_mem <- mkMultiMemIfcToMemIfc(mkMemPackManyTo1(containerDataSz, multiPortMem));
        pack_mem_multi <- mkMemPackManyTo1(containerDataSz, multiPortMem);
        pack_mem <- mkMultiMemIfcToMemIfc(pack_mem_multi);
    end
    else
    begin
        // Object bigger than one container.  Use multiple containers for
        // each object.
        // pack_mem <- mkMultiMemIfcToMemIfc(mkMemPack1ToMany(containerDataSz, multiPortMem));
        pack_mem_multi <- mkMemPack1ToMany(containerDataSz, multiPortMem);
        pack_mem <- mkMultiMemIfcToMemIfc(pack_mem_multi);
    end
*/
    
    rule processNewReadReq (!tpl_3(reqQ.first()) && !reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        mem.readReq(addr);
        $display($format("apBusMemRead: port=%0d, addr=0x%x", busId, addr));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgRead, list2(fromInteger(busId), zeroExtendNP(pack(addr))));
        end
`endif
        if (pack(size) > 1)
        begin
            reqPending <= True;
            memBurstNum <= unpack(1);
        end
        else
        begin
            reqQ.deq();
        end
    endrule
    
    rule processPendingReadReq (!tpl_3(reqQ.first()) && reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        t_USER_ADDR mem_addr = unpack(pack(addr) + pack(memBurstNum));
        mem.readReq(mem_addr);
        $display($format("apBusMemBurstRead: port=%0d, addr=0x%x", busId, mem_addr));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgRead, list2(fromInteger(busId), zeroExtendNP(pack(mem_addr))));
        end
`endif
        if (pack(memBurstNum) == (pack(size)-1) )
        begin
            reqPending <= False;
            reqQ.deq();
        end
        else
        begin
            memBurstNum <= unpack(pack(memBurstNum)+1);
        end
    endrule

    rule processNewWriteReq (tpl_3(reqQ.first()) && !reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        let data = writeDataQ.first();
        writeDataQ.deq();
        mem.write(addr, data);
        $display($format("apBusMemWrite: port=%0d, addr=0x%x, data=0x%x", busId, addr, data));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgWrite, list3(fromInteger(busId), zeroExtendNP(pack(addr)), resize(pack(data))));
        end
`endif
        if (pack(size) > 1)
        begin
            reqPending <= True;
            memBurstNum <= unpack(1);
        end
        else
        begin
            reqQ.deq();
        end
    endrule
    
    rule processPendingWriteReq (tpl_3(reqQ.first()) && reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        let data = writeDataQ.first();
        writeDataQ.deq();
        t_USER_ADDR mem_addr = unpack(pack(addr) + pack(memBurstNum));
        mem.write(mem_addr, data);
        $display($format("apBusMemBurstWrite: port=%0d, addr=0x%x, data=0x%x", busId, mem_addr, data));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgWrite, list3(fromInteger(busId), zeroExtendNP(pack(mem_addr)), resize(pack(data))));
        end
`endif
        if (pack(memBurstNum) == (pack(size)-1) )
        begin
            reqPending <= False;
            reqQ.deq();
        end
        else
        begin
            memBurstNum <= unpack(pack(memBurstNum)+1);
        end
    endrule

    // receive read response from memory and forward it to bus
    rule recvResp (True);
        t_MEM_DATA resp <- mem.readRsp();
        bus.readRsp((resp));
        $display($format("apBusRecvResp: port=%0d, data=0x%x", busId, resp));
    endrule

endmodule
`endif
//
// mkHlsApBusMemConnection --
//     Connect the HLS ap Bus interface with LEAP memory interface.
//
module mkHlsApBusMemConnection1#(MEMORY_IFC#(t_MEM_ADDR, t_MEM_DATA) mem, 
                                                   HLS_AP_BUS_IFC#(t_AP_ADDR_SZ, t_AP_DATA_SZ) bus, 
                                                   NumTypeParam#(t_MEM_DATA_SZ) containerDataSz, 
                                                   Bool verbose, 
                                                   Integer busId)
    // interface:
    ()
    provisos (Bits#(t_MEM_ADDR, t_MEM_ADDR_SZ),
              Alias#(Bit#(t_MEM_DATA_SZ), t_MEM_DATA),
              NumAlias#(MEM_PACK_CONTAINER_READ_PORTS#(1, t_AP_DATA_SZ, t_MEM_DATA_SZ), n_MEM_READERS),
              NumAlias#(TSub#(TAdd#(t_MEM_ADDR_SZ, MEM_PACK_SMALLER_OBJ_IDX_SZ#((t_AP_DATA_SZ), t_MEM_DATA_SZ)),
                              MEM_PACK_LARGER_OBJ_IDX_SZ#((t_AP_DATA_SZ), t_MEM_DATA_SZ)), t_USER_ADDR_SZ),
              Alias#(Bit#(t_USER_ADDR_SZ), t_USER_ADDR),
              Alias#(Bit#(t_AP_ADDR_SZ), t_AP_ADDR),
              Alias#(Bit#(t_AP_DATA_SZ), t_AP_DATA)
            );

    FIFOLevelIfc#(Tuple3#(t_USER_ADDR, t_USER_ADDR, Bool), 16) reqQ <- mkFIFOLevel();
    FIFOF#(t_AP_DATA) writeDataQ <- mkSizedFIFOF(8);
    Reg#(Bool) busWriteBurstPending <- mkReg(False);
    Reg#(t_AP_ADDR) burstSize <- mkReg(unpack(0));
    Reg#(t_AP_ADDR) writeDataNum <- mkReg(unpack(0));
    

    // get memory request from bus
    rule getReadReq (!bus.writeReqEn);
        reqQ.enq(tuple3(resize(bus.reqAddr), resize(bus.reqSize), False));
        $display($format("apBusGetReadReq: port=%0d, addr=0x%x, size=0x%x", busId, bus.reqAddr, bus.reqSize));
    endrule
    rule getWriteReq (bus.writeReqEn && !busWriteBurstPending);
        reqQ.enq(tuple3(resize(bus.reqAddr), resize(bus.reqSize), True));
        writeDataQ.enq(bus.writeData);
        $display($format("apBusGetWriteReq: port=%0d, addr=0x%x, size=0x%x, data=0x%x", busId, bus.reqAddr, bus.reqSize, bus.writeData));
        if (pack(bus.reqSize) > 1)
        begin
            busWriteBurstPending <= True;
            burstSize <= bus.reqSize;
            writeDataNum <= 1;
        end
    endrule
    rule getWriteBurstPendingData (bus.writeReqEn && busWriteBurstPending);
        writeDataQ.enq(bus.writeData);
        $display($format("apBusGetWriteBurstPending: port=%0d, data=0x%x", busId, bus.writeData));
        if (writeDataNum == (burstSize-1) )
        begin
            busWriteBurstPending <= False;
        end
        else
        begin
            writeDataNum <= writeDataNum+1;
        end
    endrule
    
    (* fire_when_enabled *)
    rule checkReqFull (reqQ.isLessThan(8) && writeDataQ.notFull);
        bus.reqNotFull();
    endrule

    // forward request to memory
    Reg#(Bool) reqPending <- mkReg(False);
    Reg#(t_USER_ADDR) memBurstNum <- mkReg(unpack(0));
   
    //
    // May need additional read port(s) to handle data items 
    // that have different sizes from the underlying scratchpad data size
    //
    // Use mkMemIfcToPseudoMultiMemSyncWrites to create the illusion of 
    // multiple read ports by multiplexing all requests on a single physical 
    // read port.  
    // 
    MEMORY_MULTI_READ_IFC#(n_MEM_READERS, t_MEM_ADDR, t_MEM_DATA) multiPortMem <- 
        mkMemIfcToPseudoMultiMemSyncWritesWrapper(mem);
    // MEMORY_MULTI_READ_IFC#(n_MEM_READERS, t_MEM_ADDR, t_MEM_DATA) multiPortMem;
    // if (valueOf(n_MEM_READERS) == 1) 
    // begin
    //     multiPortMem <- mkMemIfcToMultiMemIfc(mem);
    // end
    // else
    // begin
    //     multiPortMem <- mkMemIfcToPseudoMultiMemSyncWrites(mem);
    // end

    MEMORY_MULTI_READ_IFC#(1, t_USER_ADDR, t_AP_DATA) pack_mem_multi;
    MEMORY_IFC#(t_USER_ADDR, t_AP_DATA) pack_mem;
    if (valueOf(t_USER_ADDR_SZ) == valueOf(t_MEM_ADDR_SZ))
    begin
        // One object per container
        pack_mem_multi <- mkMemPack1To1(containerDataSz, multiPortMem);
        pack_mem <- mkMultiMemIfcToMemIfc(pack_mem_multi);
    end
    else if (valueOf(t_USER_ADDR_SZ) > valueOf(t_MEM_ADDR_SZ))
    begin
        // Multiple objects per container
        // pack_mem <- mkMultiMemIfcToMemIfc(mkMemPackManyTo1(containerDataSz, multiPortMem));
        pack_mem_multi <- mkMemPackManyTo1(containerDataSz, multiPortMem);
        pack_mem <- mkMultiMemIfcToMemIfc(pack_mem_multi);
    end
    else
    begin
        // Object bigger than one container.  Use multiple containers for
        // each object.
        // pack_mem <- mkMultiMemIfcToMemIfc(mkMemPack1ToMany(containerDataSz, multiPortMem));
        pack_mem_multi <- mkMemPack1ToMany(containerDataSz, multiPortMem);
        pack_mem <- mkMultiMemIfcToMemIfc(pack_mem_multi);
    end
    
    rule processNewReadReq (!tpl_3(reqQ.first()) && !reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        pack_mem.readReq(addr);
        $display($format("apBusMemRead: port=%0d, addr=0x%x", busId, addr));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgRead, list2(fromInteger(busId), zeroExtendNP(pack(addr))));
        end
`endif
        if (pack(size) > 1)
        begin
            reqPending <= True;
            memBurstNum <= unpack(1);
        end
        else
        begin
            reqQ.deq();
        end
    endrule
    
    rule processPendingReadReq (!tpl_3(reqQ.first()) && reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        t_USER_ADDR mem_addr = unpack(pack(addr) + pack(memBurstNum));
        pack_mem.readReq(mem_addr);
        $display($format("apBusMemBurstRead: port=%0d, addr=0x%x", busId, mem_addr));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgRead, list2(fromInteger(busId), zeroExtendNP(pack(mem_addr))));
        end
`endif
        if (pack(memBurstNum) == (pack(size)-1) )
        begin
            reqPending <= False;
            reqQ.deq();
        end
        else
        begin
            memBurstNum <= unpack(pack(memBurstNum)+1);
        end
    endrule

    rule processNewWriteReq (tpl_3(reqQ.first()) && !reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        let data = writeDataQ.first();
        writeDataQ.deq();
        pack_mem.write(addr, data);
        $display($format("apBusMemWrite: port=%0d, addr=0x%x, data=0x%x", busId, addr, data));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgWrite, list3(fromInteger(busId), zeroExtendNP(pack(addr)), resize(pack(data))));
        end
`endif
        if (pack(size) > 1)
        begin
            reqPending <= True;
            memBurstNum <= unpack(1);
        end
        else
        begin
            reqQ.deq();
        end
    endrule
    
    rule processPendingWriteReq (tpl_3(reqQ.first()) && reqPending);
        match {.addr, .size, .is_write} = reqQ.first();
        let data = writeDataQ.first();
        writeDataQ.deq();
        t_USER_ADDR mem_addr = unpack(pack(addr) + pack(memBurstNum));
        pack_mem.write(mem_addr, data);
        $display($format("apBusMemBurstWrite: port=%0d, addr=0x%x, data=0x%x", busId, mem_addr, data));
`ifndef MEM_TEST_STDIO_DEBUG_ENABLE_Z
        if (verbose)
        begin
            stdio.printf(msgWrite, list3(fromInteger(busId), zeroExtendNP(pack(mem_addr)), resize(pack(data))));
        end
`endif
        if (pack(memBurstNum) == (pack(size)-1) )
        begin
            reqPending <= False;
            reqQ.deq();
        end
        else
        begin
            memBurstNum <= unpack(pack(memBurstNum)+1);
        end
    endrule

    // receive read response from memory and forward it to bus
    rule recvResp (True);
        t_AP_DATA resp <- pack_mem.readRsp();
        bus.readRsp(resp);
        $display($format("apBusRecvResp: port=%0d, data=0x%x", busId, resp));
    endrule

endmodule

endpackage
