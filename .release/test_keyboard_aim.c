#include <assert.h>
#include <stdio.h>
#include "../source/lindberghrecomp/src/runtime/keyboard_aim.h"
static KeyboardAim run(int hz,int w,int h){KeyboardAim a;keyboard_aim_init(&a);keyboard_aim_key(&a,0,KA_RIGHT,1);keyboard_aim_key(&a,1,KA_UP,1);for(int i=0;i<hz;i++)keyboard_aim_step(&a,1.f/hz,w,h);return a;}
int main(void){
 for(int pass=0;pass<3;pass++){
  int w=pass==0?640:pass==1?1920:3840,h=pass==0?480:pass==1?1080:2160;
  KeyboardAim a=run(10,w,h),b=run(60,w,h),c=run(144,w,h);
  assert(fabsf(a.x[0]-b.x[0])<.00002f&&fabsf(b.x[0]-c.x[0])<.00002f);
  assert(a.x[1]==.65f&&a.y[0]==.5f&&a.y[1]==0);
 }
 KeyboardAim a;keyboard_aim_init(&a);keyboard_aim_key(&a,0,KA_LEFT,1);keyboard_aim_key(&a,0,KA_RIGHT,1);keyboard_aim_step(&a,.1f,1280,720);assert(a.x[0]==.35f);
 keyboard_aim_key(&a,0,KA_LEFT,0);keyboard_aim_step(&a,.1f,1280,720);assert(a.x[0]>.35f&&a.x[1]==.65f);
 keyboard_aim_clear(&a);float x=a.x[0];keyboard_aim_step(&a,.1f,1280,720);assert(a.x[0]==x);
 keyboard_aim_key(&a,1,KA_DOWN,1);for(int i=0;i<100;i++)keyboard_aim_step(&a,.1f,1280,720);assert(a.y[1]==1);
 keyboard_aim_clear(&a);keyboard_aim_key(&a,1,KA_LEFT,1);for(int i=0;i<100;i++)keyboard_aim_step(&a,.1f,1280,720);assert(a.x[1]==0&&a.x[0]==x);
 puts("PASS independent keyboard aim, 10/60/144 Hz, resize-safe positions, opposing keys, clamping and release");return 0;
}
