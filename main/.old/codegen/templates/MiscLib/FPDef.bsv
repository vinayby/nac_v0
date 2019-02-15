package FPDef;
import FloatingPoint::*;

typedef Bit#(1) Bit1;

typedef 8 ExpWidth;
typedef 23 MantissaWidth;
typedef FloatingPoint#(ExpWidth,MantissaWidth) FpuDataType;

typedef 2 AddDepth;
typedef 2 SubDepth;
typedef 2 MultDepth;
typedef 6 DivDepth;

endpackage
