#include <assert.h>
#include <stdio.h>
#include "../source/lindberghrecomp/src/runtime/xr_controls.h"
int main(void)
{
    for(int dual=0;dual<2;dual++)for(int down=0;down<2;down++)
    for(int previous=0;previous<2;previous++)for(int menu=0;menu<2;menu++) {
        assert(!lg_xr_debug_capture_requested(0,dual,down,previous,menu));
        assert(lg_xr_debug_capture_requested(1,dual,down,previous,menu)==(!dual&&down&&!previous&&!menu));
    }
    puts("OpenXR X: capture disabled by default; diagnostic edge/menu/dual guards passed");
    return 0;
}
