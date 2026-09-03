#ifndef BENCHMARK_WIFI_H
#define BENCHMARK_WIFI_H

#include <Arduino.h>

#ifndef WL_CONNECTED
#define WL_CONNECTED 3
#endif

class BenchmarkWiFiClass {
public:
    bool conectado = true;
    int chamadasStatus = 0;
    int chamadasReconnect = 0;

    int status() {
        chamadasStatus++;

        if (conectado) {
            return WL_CONNECTED;
        }

        return 0;
    }

    void reconnect() {
        chamadasReconnect++;
    }
};

extern BenchmarkWiFiClass WiFi;

#endif
