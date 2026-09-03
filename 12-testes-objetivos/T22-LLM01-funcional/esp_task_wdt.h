#ifndef BENCHMARK_ESP_TASK_WDT_H
#define BENCHMARK_ESP_TASK_WDT_H

typedef int esp_err_t;

#define ESP_OK 0

extern int benchmarkWdtReset;

inline esp_err_t esp_task_wdt_reset() {
    benchmarkWdtReset++;
    return ESP_OK;
}

#endif
