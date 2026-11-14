/* Limits a game's camera/view aspect factor relative to its 960x544 Vita frame.
 * The custom fork permits narrow screens (16:10) without stretching.
 * A/B rollback restores the prior native-aspect letterboxing policy. */
#ifndef NATIV_ASPECT_FACTOR_H
#define NATIV_ASPECT_FACTOR_H
#include <string.h>
/* Exact requested picture aspect; Window is handled by the caller. */
static inline float nativ_aspect_preset(const char *name) {
    if (!name) return 0.0f;
    if (!strcmp(name, "16:9")) return 16.0f / 9.0f;
    if (!strcmp(name, "16:10")) return 16.0f / 10.0f;
    if (!strcmp(name, "21:9")) return 21.0f / 9.0f;
    if (!strcmp(name, "32:9")) return 32.0f / 9.0f;
    return 0.0f;
}

static inline float nativ_aspect_factor(float k, int allowNarrow) {
    if (!allowNarrow && k < 1.02f) return 1.0f;
    if (k < 0.75f) return 0.75f;
    if (k > 2.5f) return 2.5f;
    return k;
}
#endif
