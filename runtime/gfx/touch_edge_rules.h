/* Vita touch reports are sampled on vblank edges rather than timestamped per API call.
 * Adapted from Luufen/nativ commit 52ec68822; pure helpers permit regression testing. */
#ifndef NATIV_TOUCH_EDGE_RULES_H
#define NATIV_TOUCH_EDGE_RULES_H
#include <stdint.h>

static inline uint32_t touch_edge_read_count(uint64_t previous, uint64_t current, uint32_t capacity) {
    if (!capacity) return 0;
    if (!previous || current <= previous) return 1;
    return current - previous < capacity ? (uint32_t)(current - previous) : capacity;
}
static inline uint64_t touch_edge_report(uint64_t current, uint32_t count, uint32_t index) {
    return current - (uint64_t)(count - 1 - index);
}
#endif
