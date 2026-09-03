#ifndef BENCHMARK_ESP_TASK_WDT_H
#define BENCHMARK_ESP_TASK_WDT_H

#include <stdint.h>

typedef int esp_err_t;

#define ESP_OK 0
#define ESP_ERR_INVALID_STATE 0x103

#ifndef portNUM_PROCESSORS
#define portNUM_PROCESSORS 2
#endif

typedef struct {
    uint32_t timeout_ms;
    uint32_t idle_core_mask;
    bool trigger_panic;
} esp_task_wdt_config_t;

extern int benchmarkWdtInit;
extern int benchmarkWdtReconfigure;
extern int benchmarkWdtAdd;

inline esp_err_t esp_task_wdt_init(
    const esp_task_wdt_config_t *config
) {
    benchmarkWdtInit++;
    return ESP_OK;
}

inline esp_err_t esp_task_wdt_reconfigure(
    const esp_task_wdt_config_t *config
) {
    benchmarkWdtReconfigure++;
    return ESP_OK;
}

inline esp_err_t esp_task_wdt_init(
    uint32_t timeout,
    bool panic
) {
    benchmarkWdtInit++;
    return ESP_OK;
}

inline esp_err_t esp_task_wdt_add(void *task) {
    benchmarkWdtAdd++;
    return ESP_OK;
}

#endif
