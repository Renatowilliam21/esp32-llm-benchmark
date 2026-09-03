#ifndef WIFI_CLIENT_H
#define WIFI_CLIENT_H

#include <Arduino.h>
#include "MockNetState.h"

class WiFiClient {
public:
    WiFiClient() {
    }

    virtual ~WiFiClient() {
    }

    void setTimeout(uint32_t timeout) {
        mockHTTP().clientTimeout = (int)timeout;
    }
};

#endif
