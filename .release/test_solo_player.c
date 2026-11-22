#include <assert.h>
#include <stdio.h>
#include "../source/lindberghrecomp/src/runtime/solo_player.h"
#include "../source/lindberghrecomp/src/runtime/gameplay_options.h"
int main(void)
{
    const unsigned first[]={CAB_P1_START,CAB_P1_TRIGGER,CAB_P1_RELOAD,CAB_P1_ACTION,CAB_P1_FIREMODE};
    const unsigned second[]={CAB_P2_START,CAB_P2_TRIGGER,CAB_P2_RELOAD,CAB_P2_ACTION,CAB_P2_FIREMODE};
    for(unsigned i=0;i<5;i++){
        assert(solo_player_buttons(first[i],1)==second[i]);
        assert(solo_player_buttons(second[i],1)==first[i]);
        assert(solo_player_buttons(first[i],0)==first[i]);
    }
    for(unsigned v=0;v<4096;v++){
        assert(solo_player_buttons(solo_player_buttons(v,1),1)==v);
        assert(solo_player_buttons(v,0)==v);
    }
    assert(solo_player_buttons(CAB_TEST|CAB_SERVICE,1)==(CAB_TEST|CAB_SERVICE));
    unsigned offscreen=gameplay_offscreen_buttons(CAB_P1_TRIGGER,1,-1,100,0,0,0,1280,720);
    assert(solo_player_buttons(offscreen,1)==CAB_P2_RELOAD);
    offscreen=gameplay_offscreen_buttons(CAB_P1_TRIGGER,0,-1,100,0,0,0,1280,720);
    assert(solo_player_buttons(offscreen,1)==0);
    for(int mode=0;mode<5;mode++){
        assert(solo_player_enabled(1,1,mode)==(mode<3));
        assert(!solo_player_enabled(1,0,mode));
        assert(!solo_player_enabled(0,1,mode));
    }
    assert(solo_player_game_buttons(CAB_P1_START|CAB_P1_TRIGGER,1,1)==(CAB_P1_START|CAB_P2_TRIGGER));
    assert(solo_player_game_buttons(CAB_P2_START|CAB_P2_RELOAD,1,1)==(CAB_P2_START|CAB_P1_RELOAD));
    puts("PASS: primary/secondary start, trigger, reload, grenade, fire mode, simultaneous inputs, service bits, defaults and co-op isolation.");
}
