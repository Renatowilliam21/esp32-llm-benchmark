#ifndef MOCK_NET_STATE_H
#define MOCK_NET_STATE_H

#include <Arduino.h>

struct MockHTTPState {
    int responseCode;
    String responseBody;

    int postCount;
    int beginCount;
    int endCount;

    bool secureCreated;
    bool insecureCalled;

    int connectTimeout;
    int httpTimeout;
    int clientTimeout;

    String contentType;
    String apiToken;

    String url;
    String postedJson;

    void reset() {
        responseCode = 200;
        responseBody = "";

        postCount = 0;
        beginCount = 0;
        endCount = 0;

        secureCreated = false;
        insecureCalled = false;

        connectTimeout = -1;
        httpTimeout = -1;
        clientTimeout = -1;

        contentType = "";
        apiToken = "";

        url = "";
        postedJson = "";
    }
};

inline MockHTTPState &mockHTTP() {
    static MockHTTPState estado;
    return estado;
}

#endif
