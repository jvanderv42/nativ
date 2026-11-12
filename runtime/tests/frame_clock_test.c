/* Run against runtime/ui/frame_clock.h without the full game runtime. */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include "frame_clock.h"
int main(void) {
	FrameClock clock = {0, 0, 16667};
	assert(fc_time_us(&clock, 0) == 0);
	assert(fc_time_us(&clock, 2) == 33334);
	fc_rebase(&clock, 2, 8333);
	assert(fc_time_us(&clock, 2) == 33334);  /* switching rate doesn't jump */
	assert(fc_time_us(&clock, 4) == 50000);  /* two 120-Hz edges */
	fc_rebase(&clock, 4, 16667);
	assert(fc_time_us(&clock, 4) == 50000);
	assert(fc_time_us(&clock, 6) == 83334);
	for (int i = 0; i < 100; ++i) {
		uint64_t e = 6 + (uint64_t)i * 2;
		uint64_t before = fc_time_us(&clock, e);
		fc_rebase(&clock, e, i % 2 ? 16667 : 8333);
		assert(fc_time_us(&clock, e) == before);
		assert(fc_time_us(&clock, e + 1) > before);
	}
	puts("frame clock: transitions and monotonicity passed");
	return 0;
}
