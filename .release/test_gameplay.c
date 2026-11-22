#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../source/lindberghrecomp/src/runtime/gameplay_options.h"
#include "../source/lindberghrecomp/src/runtime/xr_controls.h"
#include "../source/lindberghrecomp/src/runtime/xr_panel.h"
int main(int argc,char **argv)
{
    const unsigned shots=CAB_P1_TRIGGER|CAB_P2_TRIGGER;
    const unsigned unrelated=CAB_P1_ACTION|CAB_P2_START;
    for(int enabled=0;enabled<2;enabled++)for(int a=0;a<2;a++)for(int b=0;b<2;b++) {
        unsigned expected=unrelated|(a?(enabled?CAB_P1_RELOAD:0):CAB_P1_TRIGGER)|(b?(enabled?CAB_P2_RELOAD:0):CAB_P2_TRIGGER);
        assert(gameplay_offscreen_buttons(shots|unrelated,enabled,a?-1:0,0,1,b?1920:1919,1079,1920,1080)==expected);
        assert(gameplay_offscreen_buttons(unrelated,enabled,-1,-1,1,-1,-1,1920,1080)==unrelated);
    }
    assert(gameplay_offscreen_buttons(CAB_P1_RELOAD,0,-1,-1,0,0,0,1920,1080)==CAB_P1_RELOAD);
    assert(gameplay_offscreen_buttons(shots,1,0,1080,0,-1,-1,1920,1080)==(CAB_P1_RELOAD|CAB_P2_TRIGGER));
    for(int disabled=0;disabled<2;disabled++)for(int dual=0;dual<2;dual++)for(int blocked=0;blocked<2;blocked++) {
        LgXrControls s=LG_XR_CONTROLS_DEFAULT;
        LgXrControlFrame f={0};f.time=1000000000;f.dual=dual;f.blocked=blocked;f.disable_offscreen_reload=disabled;
        f.trigger[0]=f.trigger[1]=1;f.aimed[0]=1;
        unsigned out=lg_xr_controls_update(&s,&f).held;
        assert((out&CAB_P1_TRIGGER)==(blocked?0:CAB_P1_TRIGGER));
        assert(!(out&CAB_P1_RELOAD));
        assert((out&CAB_P2_RELOAD)==(!blocked&&dual&&!disabled?CAB_P2_RELOAD:0));
        assert(!(out&CAB_P2_TRIGGER));
        f.trigger[0]=f.trigger[1]=0;f.grip[1]=1;f.aimed[0]=0;
        out=lg_xr_controls_update(&s,&f).held;
        assert((out&CAB_P1_RELOAD)==(blocked?0:CAB_P1_RELOAD));
    }
    LgXrSettings cfg=LG_XR_SETTINGS_DEFAULT;
    assert(cfg.offscreen_reload==1 && cfg.blood_splatter==0 && cfg.foveation==3);
    XpPanel p={0};XmItem items[XP_COUNT];int hand=1;
    xp_items(&p,&cfg,hand,0,cfg.resolution,cfg.width,items);
    assert(!strcmp(items[XP_OFFSCREEN].value,"On") && !strcmp(items[XP_BLOOD].value,"Original"));
    assert(xp_choose(&p,&cfg,&hand,XP_OFFSCREEN,NULL,0)&XP_SAVE);
    assert(xp_choose(&p,&cfg,&hand,XP_BLOOD,NULL,0)&XP_SAVE);
    assert(cfg.offscreen_reload==0 && cfg.blood_splatter==1);
    for(int row=0;row<XP_COUNT;row++)
        assert(xm_row_at(.5f,(72+row*36+18)/(float)XM_H,XP_COUNT)==row);
    if(argc>1){
        unsigned char *pixels=malloc(XM_W*XM_H*4);assert(pixels);
        xp_items(&p,&cfg,hand,0,cfg.resolution,cfg.width,items);
        xm_paint(pixels,"HOTD4 VR Settings",items,XP_COUNT,XP_BLOOD,"Aim and pull trigger to change");
        FILE *image=fopen(argv[1],"wb");assert(image);fprintf(image,"P6\n%d %d\n255\n",XM_W,XM_H);
        for(int i=0;i<XM_W*XM_H;i++)fwrite(pixels+i*4,1,3,image);
        fclose(image);free(pixels);
    }
    xr_settings_save(&cfg);cfg=(LgXrSettings)LG_XR_SETTINGS_DEFAULT;xr_settings_load(&cfg);
    assert(cfg.offscreen_reload==0 && cfg.blood_splatter==1);
    FILE *old=fopen("vr.cfg","w");assert(old);fputs("gun off\n",old);fclose(old);
    cfg=(LgXrSettings)LG_XR_SETTINGS_DEFAULT;xr_settings_load(&cfg);
    assert(cfg.show_gun==0 && cfg.offscreen_reload==1 && cfg.blood_splatter==0);remove("vr.cfg");
    gameplay_options_set(0,1);gameplay_options_save();gameplay_options_set(1,0);gameplay_options_load();
    assert(!gameplay_offscreen_reload() && gameplay_blood_splatter());
    remove("offscreen-reload.txt");remove("blood-effects.txt");gameplay_options_load();
    assert(gameplay_offscreen_reload() && !gameplay_blood_splatter());
    puts("PASS: independent P1/P2 off-screen trigger, option, VR grip/menu, old configs and persistent profiles");
    return 0;
}
