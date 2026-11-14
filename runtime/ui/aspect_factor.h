/* Limits a game's camera/view aspect factor relative to its 960x544 Vita frame.
 * The custom fork permits narrow screens (16:10) without stretching.
 * A/B rollback restores the prior native-aspect letterboxing policy. */
#ifndef NATIV_ASPECT_FACTOR_H
#define NATIV_ASPECT_FACTOR_H
static inline float nativ_aspect_factor(float k, int allowNarrow) {
    if (!allowNarrow && k < 1.02f) return 1.0f;
    if (k < 0.75f) return 0.75f;
    if (k > 2.5f) return 2.5f;
    return k;
}
#endif
