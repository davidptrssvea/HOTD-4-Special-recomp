#include <assert.h>
#include <stdio.h>
#include "../source/lindberghrecomp/src/runtime/coop_mouse.h"
int main(void){
 CoopMouse m;coop_mouse_init(&m,2560,1440,0);coop_mouse_motion(&m,0,0,100,100,20,20,2,2,1,2560,1440);assert(m.target_x==1280);
 coop_mouse_motion(&m,1,1,110,80,0,0,2,2,1.5,2560,1440);assert(m.target_x==1310 && m.target_y==660);
 coop_mouse_motion(&m,0,1,500,500,0,0,2,2,1.5,2560,1440);assert(m.target_x==1310 && m.target_y==660);
 coop_mouse_motion(&m,1,1,490,510,0,0,2,2,1.5,2560,1440);assert(m.target_x==1280 && m.target_y==690);
 coop_mouse_publish(&m,0,16);assert(m.x==1280 && m.y==690);
 coop_mouse_motion(&m,1,0,0,0,-5,1445,1,1,1,2560,1440);coop_mouse_publish(&m,0,17);assert(m.x==-5 && m.y==1445);
 coop_mouse_motion(&m,1,1,100000,100000,0,0,2,2,8,2560,1440);assert(m.target_x==2559 && m.target_y==1439);
 coop_mouse_init(&m,2560,1440,0xfffffff8u);m.target_x=2000;coop_mouse_publish(&m,1,8);assert(m.x>1280 && m.x<2000);
 for(int i=0;i<40;i++) { coop_mouse_publish(&m,1,24+16*i); }
 assert(m.x==2000);
 puts("PASS: isolated cursors, physical/warp baselines, relative speed, absolute offscreen, clamp, smoothing/time wrap");
}
