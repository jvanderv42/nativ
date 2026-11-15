/* Test 16:10 window ratio, native, ultrawide and rollback behavior. */
#include <stdio.h>
#include <math.h>
#include "aspect_factor.h"
int main(void) {
    const float native = 960.0f / 544.0f;
    const float ratio16x10 = (16.0f / 10.0f) / native;
    int bad = 0;
    bad += fabsf(nativ_aspect_preset("16:9") - (16.0f/9.0f)) > 0.0001f;
    bad += fabsf(nativ_aspect_preset("16:10") - 1.6f) > 0.0001f;
    bad += fabsf(nativ_aspect_preset("21:9") - (21.0f/9.0f)) > 0.0001f;
    bad += nativ_aspect_preset("native") != 0.0f;

    bad += fabsf(nativ_aspect_factor(ratio16x10, 1) - ratio16x10) > 0.0001f;
    bad += nativ_aspect_factor(ratio16x10, 0) != 1.0f;
    bad += nativ_aspect_factor(1.0f, 1) != 1.0f;
    bad += fabsf(nativ_aspect_factor((21.0f / 9.0f) / native, 1) - (21.0f / 9.0f) / native) > 0.0001f;
    bad += nativ_aspect_factor(4.0f, 1) != 2.5f;
    printf("aspect factor rules: %s\n", bad ? "FAILED" : "passed");
    return bad != 0;
}
