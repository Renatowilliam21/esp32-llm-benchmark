#ifndef WIFI_CLIENT_SECURE_H
#define WIFI_CLIENT_SECURE_H

#include <Arduino.h>
#include "WiFiClient.h"
#include "MockNetState.h"

class WiFiClientSecure : public WiFiClient {
public:
    WiFiClientSecure() : WiFiClient() {
        mockHTTP().secureCreated = true;
    }

    void setInsecure() {
        mockHTTP().insecureCalled = true;
    }
};

#endif
