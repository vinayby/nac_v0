package FPUWrap;
import FPDef::*;
import Vector::*;
import FPUModel::*;

typedef struct{
	Bit1 valid;
	FpuDataType x;
	FpuDataType y;
}FpuReq deriving (Bits, Eq);

typedef struct{
	Bit1 valid;
	FpuDataType res;
}FpuRes deriving (Bits, Eq);


interface FpuUnit;
    method Action put(FpuReq in);
    method FpuRes get();
endinterface

interface Fpu#(numeric type depth);
    method Action put(FpuReq in);
    method FpuRes get();
endinterface

module mkFpuWrap#(OpType op)(Fpu#(depth));
	Integer dpth = valueOf(depth); 
	Fp#(depth) fpu <- mkFpu(op);
	Vector#(depth,Reg#(Bit1)) pipe <- replicateM(mkReg(0));
	
	rule r;
		for(Integer i=1; i<dpth; i=i+1) begin
			pipe[i] <= pipe[i-1];
		end
	endrule

    method Action put(FpuReq in);
		fpu.put(FpuIn{x:in.x, y:in.y});
		pipe[0] <= in.valid;
	endmethod
    method FpuRes get();	
		return FpuRes{res:fpu.get, valid:pipe[dpth-1]};
	endmethod
endmodule

(* synthesize *)
module mkFPUAdd(FpuUnit);
	Fpu#(AddDepth) add <- mkFpuWrap(Add);
	method put = add.put;
	method get = add.get;
endmodule

(* synthesize *)
module mkFPUSub(FpuUnit);
	Fpu#(SubDepth) sub <- mkFpuWrap(Sub);
	method put = sub.put;
	method get = sub.get;
endmodule

(* synthesize *)
module mkFPUMult(FpuUnit);
	Fpu#(MultDepth) mult <- mkFpuWrap(Mult);
	method put = mult.put;
	method get = mult.get;
endmodule

(* synthesize *)
module mkFPUDiv(FpuUnit);
	Fpu#(DivDepth) div <- mkFpuWrap(Div);
	method put = div.put;
	method get = div.get;
endmodule

endpackage

