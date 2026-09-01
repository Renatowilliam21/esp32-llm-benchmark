#include <Wire.h>

void escreverEEPROM(uint16_t endereco, uint8_t valor) {
    Wire.beginTransmission(0x50);
    Wire.write((uint8_t)(endereco >> 8));
    Wire.write((uint8_t)(endereco & 0xFF));
    Wire.write(valor);
    Wire.endTransmission();
    delay(5);
}