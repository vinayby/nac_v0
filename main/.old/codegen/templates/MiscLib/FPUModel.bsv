package FPUModel;
import FPDef::*;
import Vector::*;
import Math::*;
import FloatingPoint::*;


typedef struct{
	FpuDataType x;
	FpuDataType y;
}FpuIn deriving (Bits, Eq);

interface FpUnit;
    method Action put(FpuIn in);
    method FpuDataType get();
endinterface

interface Fp#(numeric type depth);
    method Action put(FpuIn in);
    method FpuDataType get();
endinterface

typedef enum {Add, Sub, Mult, Div} OpType deriving (Eq, Bits);

module mkFpu#(OpType op)(Fp#(depth));
	Integer dpth = valueOf(depth); 

	Vector#(depth,Reg#(FpuDataType)) pipe <- replicateM(mkRegU());
	rule r;
		for(Integer i=1; i<dpth; i=i+1) begin
			pipe[i] <= pipe[i-1];
		end
	endrule
    method Action put(FpuIn in);
		case(op)
			Add: pipe[0] <= in.x+in.y;
			Sub: pipe[0] <= in.x-in.y;
			Mult: pipe[0] <= in.x*in.y;
			Div: pipe[0] <= in.x/in.y;
		endcase		
	endmethod

    method FpuDataType get();
		return pipe[dpth-1];
    endmethod
endmodule

(* synthesize *)
(* always_ready = "put,get" *)
(* always_enabled = "get" *)
module mkAdd(FpUnit);
	Fp#(AddDepth) add <- mkFpu(Add);
	method put = add.put;
	method FpuDataType get();
		return add.get;
	endmethod
endmodule
(* synthesize *)
(* always_ready = "put,get" *)
(* always_enabled = "get" *)
module mkSub(FpUnit);
	Fp#(SubDepth) sub <- mkFpu(Sub);
	method put = sub.put;
	method FpuDataType get();
		return sub.get;
	endmethod
endmodule
(* synthesize *)
(* always_ready = "put,get" *)
(* always_enabled = "get" *)
module mkMult(FpUnit);
	Fp#(MultDepth) mult <- mkFpu(Mult);
	method put = mult.put;
	method FpuDataType get();
		return mult.get;
	endmethod
endmodule
(* synthesize *)
(* always_ready = "put,get" *)
(* always_enabled = "get" *)
module mkDiv(FpUnit);
	Fp#(DivDepth) div <- mkFpu(Div);
	method put = div.put;
	method FpuDataType get();
		return div.get;
	endmethod
endmodule

endpackage
