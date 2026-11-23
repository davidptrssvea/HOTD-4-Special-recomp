#ifndef HOTD4_KEYBOARD_AIM_H
#define HOTD4_KEYBOARD_AIM_H
#include <math.h>
/* Normalized positions survive render-size changes. Keys are event-driven,
 * movement is elapsed-time based, and opposing directions cancel. */
enum { KA_UP=1,KA_DOWN=2,KA_LEFT=4,KA_RIGHT=8 };
typedef struct { float x[2],y[2]; unsigned held[2]; } KeyboardAim;
static inline void keyboard_aim_init(KeyboardAim *a)
{ *a=(KeyboardAim){.x={.35f,.65f},.y={.5f,.5f}}; }
static inline void keyboard_aim_clear(KeyboardAim *a){a->held[0]=a->held[1]=0;}
static inline void keyboard_aim_key(KeyboardAim *a,int player,unsigned bit,int down)
{if(down)a->held[player]|=bit;else a->held[player]&=~bit;}
static inline void keyboard_aim_step(KeyboardAim *a,float seconds,int width,int height)
{
 if(width<2||height<2||!isfinite(seconds)||seconds<=0)return;
 seconds=fminf(seconds,.1f);
 for(int p=0;p<2;p++){
  unsigned b=a->held[p];float dx=!!(b&KA_RIGHT)-!!(b&KA_LEFT),dy=!!(b&KA_DOWN)-!!(b&KA_UP);
  float length=sqrtf(dx*dx+dy*dy);if(!length)continue;
  float distance=.9f*seconds/length;
  a->x[p]=fmaxf(0,fminf(1,a->x[p]+dx*distance*(height-1)/(width-1)));
  a->y[p]=fmaxf(0,fminf(1,a->y[p]+dy*distance));
 }
}
#endif
