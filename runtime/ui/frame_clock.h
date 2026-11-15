/* Fixed guest-clock conversion across 60/120 Hz virtual vblank transitions.
 * Pure integer arithmetic; callers synchronize access to FrameClock.
 * A rebase preserves elapsed guest time when the vblank period changes. */
#ifndef FRAME_CLOCK_H
#define FRAME_CLOCK_H
#include <stdint.h>
typedef struct {
	uint64_t origin_edges;
	uint64_t origin_us;
	uint64_t period_us;
} FrameClock;
static inline uint64_t fc_time_us(const FrameClock *clock, uint64_t edges) {
	return clock->origin_us + (edges >= clock->origin_edges ? edges - clock->origin_edges : 0) * clock->period_us;
}
static inline void fc_rebase(FrameClock *clock, uint64_t edges, uint64_t new_period_us) {
	clock->origin_us = fc_time_us(clock, edges);
	clock->origin_edges = edges;
	clock->period_us = new_period_us;
}
#endif
