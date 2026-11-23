#ifndef HOTD4_CONTROLS_H
#define HOTD4_CONTROLS_H
enum { HC_PAUSE=11,HC_RESTART,HC_FULLSCREEN,HC_CROSSHAIR,HC_MOUSELOCK,HC_KB1_UP,HC_KB1_DOWN,HC_KB1_LEFT,HC_KB1_RIGHT,HC_KB1_SHOOT,HC_KB1_RELOAD,HC_KB1_GRENADE,HC_KB1_FIREMODE,HC_KB2_UP,HC_KB2_DOWN,HC_KB2_LEFT,HC_KB2_RIGHT,HC_KB2_SHOOT,HC_KB2_RELOAD,HC_KB2_GRENADE,HC_KB2_FIREMODE,HC_KB_SERVICE,HC_COUNT };
static const char *hc_keys[HC_COUNT]={"coin1","start1","trigger","reload","action","firemode","coin2","start2","test","service","mute","pause","restart","fullscreen","crosshair_toggle","mouse_lock","kb1_up","kb1_down","kb1_left","kb1_right","kb1_shoot","kb1_reload","kb1_grenade","kb1_firemode","kb2_up","kb2_down","kb2_left","kb2_right","kb2_shoot","kb2_reload","kb2_grenade","kb2_firemode","kb_service"};
static const wchar_t *hc_labels[HC_COUNT]={L"Add Coin (P1)",L"Start (P1)",L"Shoot",L"Reload / Shake",L"Grenade",L"Fire Mode",L"Add Coin (P2)",L"Start (P2)",L"Test Menu",L"Service",L"Mute",L"Pause",L"Restart",L"Fullscreen",L"Toggle Crosshair",L"Mouse Lock",L"P1 Aim Up (Keyboard)",L"P1 Aim Down (Keyboard)",L"P1 Aim Left (Keyboard)",L"P1 Aim Right (Keyboard)",L"P1 Shoot (Keyboard)",L"P1 Reload / Shake (Keyboard)",L"P1 Grenade (Keyboard)",L"P1 Fire Mode (Keyboard)",L"P2 Aim Up (Keyboard)",L"P2 Aim Down (Keyboard)",L"P2 Aim Left (Keyboard)",L"P2 Aim Right (Keyboard)",L"P2 Shoot (Keyboard)",L"P2 Reload / Shake (Keyboard)",L"P2 Grenade (Keyboard)",L"P2 Fire Mode (Keyboard)",L"Service (Keyboard)"};
static const int hc_defaults[HC_COUNT]={'5','1',-1,-3,' ','f','6','2','t','s','m',SDLK_ESCAPE,SDLK_F6,SDLK_F11,SDLK_F2,SDLK_F1,SDLK_UP,SDLK_DOWN,SDLK_LEFT,SDLK_RIGHT,SDLK_RCTRL,SDLK_RSHIFT,SDLK_RALT,SDLK_END,'w','s','a','d',SDLK_SPACE,'q','e',SDLK_TAB,SDLK_F10};
static int hc_loaded,hc_custom,hc_values[HC_COUNT];
static char hc_path[2048];
static void hc_init(void)
{
    if(hc_loaded)return;hc_loaded=1;
    memcpy(hc_values,hc_defaults,sizeof hc_values);
    const char*d=getenv("HOTD4_SETTINGS_DIR");
    if(d&&*d)snprintf(hc_path,sizeof hc_path,"%s/controls-profile.txt",d);
    else {GetModuleFileNameA(NULL,hc_path,sizeof hc_path);char*p=strrchr(hc_path,'\\');if(p)strcpy(p+1,"controls-profile.txt");else strcpy(hc_path,"controls-profile.txt");}
    /* The launcher runs from the dump's elf directory. Controls belong to
       the installed app's INI, never to files in the source arcade dump. */
    char ini[2048];snprintf(ini,sizeof ini,"%s",hc_path);char*a=strrchr(ini,'/'),*b=strrchr(ini,'\\'),*p=a&&(!b||a>b)?a:b;
    if(p)strcpy(p+1,"lindbergh.ini");else strcpy(ini,"lindbergh.ini");
    FILE*f=fopen(ini,"rb");char line[256],name[64],value[128];
    if(f){while(fgets(line,sizeof line,f)){if(sscanf(line," %63[^= ] = %127s",name,value)!=2)continue;for(int i=0;i<11;i++)if(!strcmp(name,hc_keys[i])){hc_values[i]=!strncmp(value,"mouse",5)?-atoi(value+5):!strcmp(value,"none")?0:!strcmp(value,"space")?32:!strcmp(value,"enter")?13:strlen(value)==1?(unsigned char)value[0]:atoi(value);}}fclose(f);}
    f=fopen(hc_path,"rb");
    if(f){if(fgets(line,sizeof line,f)&&!strncmp(line,"HOTD4-CONTROLS-1",16)){hc_custom=1;int v;while(fgets(line,sizeof line,f))if(sscanf(line,"%63s %d",name,&v)==2)for(int i=0;i<HC_COUNT;i++)if(!strcmp(name,hc_keys[i])&&v>=-5&&v<=0x10ffff+SDLK_SCANCODE_MASK&&!(i>=11&&v<=0))hc_values[i]=v;}fclose(f);}
    for(int i=0;i<11;i++)settings()->bind[i]=hc_values[i];
}
static int hc_get(int id){hc_init();return id>=0&&id<HC_COUNT?hc_values[id]:0;}
static int hc_matches(int id,int key){return key!=0&&hc_get(id)==key;}
static void hc_name(int id,wchar_t*out,int n)
{
    char text[100];settings_binding_name(hc_get(id),text,sizeof text);MultiByteToWideChar(CP_UTF8,0,text,-1,out,n);out[n-1]=0;
}
/* Mouse/gun actions and keyboard-player actions run in different modes.
 * System, coin and start bindings are common and must remain unique. */
static int hc_conflict(int a,int b)
{
 int an=(a>=2&&a<=5)||a==9,bn=(b>=2&&b<=5)||b==9;
 return !((an&&b>=HC_KB1_UP)||(bn&&a>=HC_KB1_UP));
}
static int hc_set(int id,int value)
{
    hc_init();if(id<0||id>=HC_COUNT||value==0||(value<0&&(id<2||id>5)))return -1;
    for(int i=0;i<HC_COUNT;i++)if(i!=id&&hc_values[i]==value&&hc_conflict(i,id))return i+1;
    int old=hc_values[id];hc_values[id]=value;char temp[2100];snprintf(temp,sizeof temp,"%s.tmp",hc_path);
    FILE*f=fopen(temp,"wb");if(!f){hc_values[id]=old;return -2;}
    fputs("HOTD4-CONTROLS-1\n",f);for(int i=0;i<HC_COUNT;i++)fprintf(f,"%s %d\n",hc_keys[i],hc_values[i]);
    int failed=ferror(f);if(fclose(f))failed=1;
    if(failed||!MoveFileExA(temp,hc_path,MOVEFILE_REPLACE_EXISTING|MOVEFILE_WRITE_THROUGH)){hc_values[id]=old;return -2;}
    hc_custom=1;for(int i=0;i<11;i++)settings()->bind[i]=hc_values[i];return 0;
}
static int hc_reset(void)
{
    hc_init();int old[HC_COUNT];memcpy(old,hc_values,sizeof old);memcpy(hc_values,hc_defaults,sizeof hc_values);
    int status=hc_set(0,hc_values[0]);if(status){memcpy(hc_values,old,sizeof old);return status;}return 0;
}
#endif
