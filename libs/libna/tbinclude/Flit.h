// Automatically generated by: ::SceMiMsg
// DO NOT EDIT
// C++ Class with SceMi Message passing for Bluespec type:  NATypes::Flit
// Generated on: Tue Sep 05 03:11:58 IST 2017
// Bluespec version: 2017.04.beta1 2017-04-17 35065

#pragma once

#include "bsv_scemi.h"

/// C++ class representing the hardware structure NATypes::Flit
/// This class has been automatically generated.
class Flit : public BSVType {
 public:
  BitT<64> m_data ;
  BitT<1> m_vc ;
  BitT<4> m_destAddr ;
  BitT<1> m_is_tail ;
  BitT<1> m_valid ;

  /// A default constructor
  Flit ()
    :  m_data()
    , m_vc()
    , m_destAddr()
    , m_is_tail()
    , m_valid()
  {}

  /// Constructor for object from a SceMiMessageData object
  /// @param msg -- the scemi message object
  /// @param off -- the starting bit offset, updated to next bit position
  Flit ( const SceMiMessageDataInterface *msg, unsigned int &off )
    : m_data(msg, off)
    , m_vc(msg, off)
    , m_destAddr(msg, off)
    , m_is_tail(msg, off)
    , m_valid(msg, off)
  {}

  /// Converts this object into its bit representation for sending as a SceMi message
  /// @param msg -- the message object written into
  /// @param off -- bit position off set in message
  /// @return next free bit position for writing
  unsigned int setMessageData (SceMiMessageDataInterface &msg, const unsigned int off=0) const {
    unsigned int running = off;
    running = m_data.setMessageData( msg, running );
    running = m_vc.setMessageData( msg, running );
    running = m_destAddr.setMessageData( msg, running );
    running = m_is_tail.setMessageData( msg, running );
    running = m_valid.setMessageData( msg, running );
    if (running != off + 71 ) {
      std::cerr << "Mismatch in sizes: " << std::dec <<  running << " vs " << (off + 71) << std::endl;
    }
    return running;
  }

  /// overload the put-to operator for Flit
  friend std::ostream & operator<< (std::ostream &os, const Flit &obj) {
    BSVType::PutTo * override = lookupPutToOverride ( obj.getClassName() );
    if ( override != 0 ) {
       return override(os, obj );
    }
    os << "{" ;
    os << "valid " << obj.m_valid ;os << " " ;
    os << "is_tail " << obj.m_is_tail ;os << " " ;
    os << "destAddr " << obj.m_destAddr ;os << " " ;
    os << "vc " << obj.m_vc ;os << " " ;
    os << "data " << obj.m_data ;os << "}" ;
    return os;
  }

  /// Adds to the stream the bit representation of this structure object
  /// @param os -- the ostream object which to append
  /// @return the ostream object
  virtual std::ostream & getBitString (std::ostream & os) const {
    m_valid.getBitString (os);
    m_is_tail.getBitString (os);
    m_destAddr.getBitString (os);
    m_vc.getBitString (os);
    m_data.getBitString (os);
  return os;
  }
  

  /// Accessor for the BSVType name for this object
  /// @param os -- the ostream object which to append
  /// @return the ostream object
  virtual std::ostream & getBSVType (std::ostream & os) const {
    os << "NATypes::Flit" ;
    return os;
  }

  /// Accessor on the size of the object in bits
  /// @return the bit size
  virtual unsigned int getBitSize () const {
    return 71;
  }

  /// returns the class name for this object
  virtual const char * getClassName() const {
    return "Flit" ;
  }

  /// returns the BSVKind for this object
  virtual BSVKind getKind() const {
    return BSV_Struct ;
  }

  /// Accessor for the count of members in object
  virtual unsigned int getMemberCount() const {
    return 5;
  };
  
  /// Accessor to member objects
  /// @param idx -- member index
  /// @return BSVType * to this object or null
  virtual BSVType * getMember (unsigned int idx) {
    switch (idx) {
      case 0: return & m_valid;
      case 1: return & m_is_tail;
      case 2: return & m_destAddr;
      case 3: return & m_vc;
      case 4: return & m_data;
      default: std::cerr << "Index error in getMember for class Flit" << std::endl ;
    };
    return 0;
  };
  
  /// Accessor for symbolic member names
  /// @param idx -- member index
  /// @return char* to this name or null
  virtual const char * getMemberName (unsigned int idx) const {
    switch (idx) {
      case 0: return "valid";
      case 1: return "is_tail";
      case 2: return "destAddr";
      case 3: return "vc";
      case 4: return "data";
      default: std::cerr << "Index error in getMemberName for class Flit" << std::endl ;
    };
    return 0;
  };
  
  
};

