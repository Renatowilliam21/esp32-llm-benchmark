#include <Wire.h>

bool detectarEeprom() {
    Wire.beginTransmission(0x50);
    return Wire.endTransmission() == 0;
}