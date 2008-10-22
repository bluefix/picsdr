#ifndef LiquidCrystalKtms_h
#define LiquidCrystalKtms_h

#include <inttypes.h>

#include <string.h>

#include "Print.h"

class LiquidCrystalKtms : public Print {
public:
  LiquidCrystalKtms(uint8_t nsck, uint8_t si, uint8_t cd,  uint8_t nreset, uint8_t nbusy,  uint8_t ncs);
  void clear();
  void home();
  void setCursor(uint8_t, uint8_t); 
  void command(uint8_t);
  void print(const char c[]);
protected:  
  virtual void write(uint8_t);
  
private:
  void send(uint8_t cnt, uint8_t data);
  //void send(uint8_t cnt, uint8_t data[12]);
  //void send(uint8_t cnt, uint8_t data[12], uint8_t start);
  
  void sendcmd( uint8_t cmd);
  void senddata( uint8_t data);
  
  //void dp(uint8_t dp, bool onoff);
  //void init();
    
  uint8_t _nsck;
  uint8_t _si;
  uint8_t _cd;
  uint8_t _nreset;
  uint8_t _nbusy;
  uint8_t _ncs;
};

#endif
