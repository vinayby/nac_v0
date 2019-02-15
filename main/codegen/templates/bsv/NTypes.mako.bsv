<%include file='Banner.mako' args="_am=_am"/>
package NTypes;
  import GetPut::*;
  import Vector::*;
  import DefaultValue::*;
  import RegFile::*;
  <%
  params = _am.psn.params
  type_table = _am.type_table
  max_msg_object_size = _am.get_max_parcel_size()
  %>
typedef ${params["NUM_USER_SEND_PORTS"]} NUM_NODES;
//typedef TLog#(${params["NUM_USER_RECV_PORTS"]}) DEST_WIDTH;
typedef ${_am.get_network_address_width()} DEST_WIDTH;
typedef TMax#(TLog#(${params["NUM_VCS"]}),1) VC_WIDTH;
typedef ${params["NUM_USER_SEND_PORTS"]} NUM_USER_SEND_PORTS;
typedef ${params["NUM_USER_RECV_PORTS"]} NUM_USER_RECV_PORTS;
typedef ${params["NUM_VCS"]} NUM_VCS;
typedef ${params["FLIT_DATA_WIDTH"]} FLIT_DATA_WIDTH;
typedef ${params["FLIT_BUFFER_DEPTH"]} FLIT_BUFFER_DEPTH;

typedef Bit#(DEST_WIDTH) DestAddr;
typedef Bit#(VC_WIDTH) VCType;
typedef Bit#(FLIT_DATA_WIDTH) FlitData;
typedef Bit#(TSub#(FLIT_DATA_WIDTH, DEST_WIDTH)) FlitData_InclSrcAddr;
typedef Bit#(NUM_VCS) NF_VCMask;
typedef Bit#(TLog#(${params["NUM_USER_RECV_PORTS"]})) RecvPortId;
typedef DestAddr PortId;
typedef DestAddr SourceAddr;
typedef Bit#(${params["NUM_USER_SEND_PORTS"]}) MultiCastMask;

// 
typedef enum {P_NONE, P_HEAD, P_TAIL, P_HEADTAIL} SendXOpt deriving (Eq, Bits, FShow);
typedef struct {
  Bit#(8)   typetag;
  Bit#(8)   address; /* dst or src depending on the context */
  Bit#(4)   nelems_packed;
  Bit#(2)   htmark;
  Bit#(512) data; 
} NARawData deriving(Eq, Bits, FShow);
interface LateralIOPort;
%if _am.enabled_lateral_data_io:
interface Put#(NARawData) putRawData;
interface Get#(NARawData) getRawData;
%endif
interface Put#(Flit) putFlit;
interface Get#(Flit) getFlit;
endinterface 

// applicable for forthnoc
typedef enum {F_BROADCAST=1, F_MULTICAST=2} McastOrBcast deriving(Eq, FShow, Bits);

// Application specific items
typedef Bit#(${_am.get_typetags_count_width()}) TypeTag;

// Flit without source
typedef struct {
	Bit#(1) valid;
	Bit#(1) is_tail;
	DestAddr destAddr;
	VCType vc;
	FlitData data;
} Flit deriving(Bits, FShow);


typedef struct {
  SourceAddr srcaddr;
  TypeTag ttag;
%if _am.unused_flit_header_bitcount > 0:
  Bit#(${_am.unused_flit_header_bitcount}) unused;
%endif
%if _am.psn.is_fnoc(): ## not applicable right now for CONNECT NoCs
  MultiCastMask mcm;
  McastOrBcast bcast_or_mcast; // bcast == 1, mcast == 2
%endif
} FlitHeaderPayLoad deriving(Bits, FShow);

%if _am.psn.is_connect_credit(): ##IF1
typedef TAdd#(TLog#(${params["FLIT_BUFFER_DEPTH"]}), 1) CreditCounterWidth;
typedef Bit#(CreditCounterWidth) CreditCounter;

typedef struct {
  Bit#(1) valid;
  VCType vc;
} Credit deriving(Bits, Eq);
%endif
endpackage
## vim: ft=mako

