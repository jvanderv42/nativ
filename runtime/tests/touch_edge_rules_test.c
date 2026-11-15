/* Read-only regression test for touch Peek/Read vblank sample accounting. */
#include <stdio.h>
#include "touch_edge_rules.h"
int main(void) {
    int bad = 0;
    bad += touch_edge_read_count(0, 100, 16) != 1;
    bad += touch_edge_read_count(100, 100, 16) != 1;
    bad += touch_edge_read_count(100, 103, 16) != 3;
    bad += touch_edge_read_count(100, 140, 16) != 16;
    bad += touch_edge_read_count(100, 103, 0) != 0;
    bad += touch_edge_report(103, 3, 0) != 101;
    bad += touch_edge_report(103, 3, 2) != 103;
    printf("touch edge rules: %s\n", bad ? "FAILED" : "passed");
    return bad != 0;
}
