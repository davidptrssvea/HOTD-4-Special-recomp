/*
 * host.c - run recompiled The House of the Dead 4 Special.
 *
 * The same engine as The House of the Dead 4, rebuilt with gcc and shipped
 * stripped: tools bounds finds its functions, and names.txt names the few the
 * runtime looks up. Everything else works as games/hotd4/src/host.c does.
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "xr_overlay.h"
#include "game_profile.h"
#include "gameplay_options.h"
#include "nn_culling.h"
#include "lindbergh_rt.h"
#include "stereo.h"

#if defined(_WIN32)
#include "cabinet_buttons.h"
#include <SDL.h>
#include "gl_posix.h"
#include "host_settings.h"
#include "render_queue.h"

extern void host_use_guest_viewport_coords(void);
extern void host_viewport_unscale(int rect[4]);
static HleHandler original_get_integer;
static HleHandler original_fread;

/* The striped wipe is a named 8x8 DXT5 texture in both language banks.
 * Clear its alpha when the game reads it. Keep the scene's timing and the
 * original files, and leave the game's other fades alone. */
static void h_read_without_wipe(CPU *c)
{
    unsigned char *data = APTR(0);
    size_t item_size = A32(1);
    original_fread(c);
    size_t bytes = item_size * c->eax;
    static const char name[] = "k_scr_wipe_001.dds";
    const size_t payload = 48 + 128;
    if (bytes < 16 + payload + 64) return;

    for (unsigned char *p = data + 16, *end = data + bytes - payload - 64 + 1;
         (p = memchr(p, 'k', (size_t)(end - p))) != NULL; ++p) {
        if (memcmp(p, name, sizeof name) || memcmp(p - 16, "DSFN", 4) ||
            memcmp(p + 32, "DSCK", 4) || memcmp(p + 48, "DDS \x7c\0\0\0", 8) ||
            memcmp(p + 60, "\x08\0\0\0\x08\0\0\0", 8) || memcmp(p + 132, "DXT5", 4)) continue;
        for (size_t block = 0; block < 64; block += 16) memset(p + payload + block, 0, 8);
        fprintf(stderr, "[hotd4sp] striped wipe hidden\n");
    }
}

static void h_get_integer(CPU *c)
{
    uint32_t name = A32(0);
    int *rect = (int *)APTR(1);
    original_get_integer(c);
    if (name == GL_VIEWPORT || name == GL_SCISSOR_BOX)
        host_viewport_unscale(rect);
}

/* Special's story uses the cabinet's event interpreter and Sofdec player.
 * Its Start handler requires the optional hold-skip flag, which is disabled
 * in many scripted Hold Your Fire scenes. */
#define EVENT_MAIN       0x0813b58cu
#define EVENT_SKIP       0x081953acu
#define OPENING_BEGIN     0x084a4ff8u
#define OPENING_FIRST_WAIT 0x084a5090u
#define OPENING_MOVIE_END 0x084a5268u
#define OPENING_HOLD_END  0x084a5ac0u
#define STAGE_TWO_BEGIN   0x084a2440u
#define STAGE_TWO_INTRO_END 0x084a4b20u
#define PLAYER_MANAGER    0x0a69f92cu
#define SOFDEC_MANAGER    0x0a69f944u
#define STORY_EVENTS_END  0x084b8d68u
#define BOSS_RIDE_CHANGE  0x084b402cu
#define BOSS_SCENE_END    0x084b41f0u
#define AIM_NORMALIZE    0x082f7494u
#define PANEL_SPRITE_DRAW   0x0817210au

void L_0813B58C(CPU *c);
void L_082F7494(CPU *c);
void L_0817210A(CPU *c);

/* Each player owns its label and grenade sprite groups.
 * Translate their native draw matrices before CellSprite builds its queued
 * geometry. Life, sight, reload warnings and grab prompts stay centred. */
static int player_panel(uint32_t sprite, uint32_t player)
{
    if (!player || sprite < player) return 0;
    uint32_t offset = sprite - player;
    return offset == 0x318 || offset == 0x3fc;
}

static void h_hud_group_draw(CPU *c)
{
    uint32_t mgr = rd32(PLAYER_MANAGER);
    uint32_t p1 = mgr ? rd32(mgr + 0x34) : 0;
    uint32_t p2 = mgr ? rd32(mgr + 0x38) : 0;
    int anchor = player_panel(c->eax, p1) ? -1 : player_panel(c->eax, p2) ? 1 : 0;
    uint32_t matrix = c->ecx;
    float k, saved[16];
    int move = anchor && matrix && stereo_wide(NULL, NULL, &k) && !stereo_flat_frame();
    if (move) {
        memcpy(saved, GP(matrix), sizeof saved);
        float scale = hud_custom_scale(); if (scale <= 0) scale = 1;
        for (unsigned i=0;i<8;i++) wrss(matrix+4*i, saved[i]*scale);
        wrss(matrix + 0x34,saved[13]+(1-scale)*768.0f*0.6f);
        wrss(matrix + 0x30, saved[12] + anchor * 512.0f * (1.0f / k - 1.0f) +
             (anchor > 0 ? 1024.0f * (1-scale) : 0));
    }
    push32(c, rd32(c->esp - 4));
    L_0817210A(c);
    if (move) memcpy(GP(matrix), saved, sizeof saved);
}

/* Sprite geometry is queued by the game; models are anchored when its
 * player-UI environment is actually rendered, in graphics queue order. */
void L_081D693E(CPU *c);
static void panel_environment(void *arg) { hud_custom_render_env((int)(intptr_t)arg); }
static void queue_panel_environment(int environment)
{
    if (glq_active()) glq_job(panel_environment, (void *)(intptr_t)environment);
    else panel_environment((void *)(intptr_t)environment);
}
static void h_panel_environment(CPU *c)
{
    queue_panel_environment(0x10000 + (int)c->edx);
    push32(c, rd32(c->esp - 4));
    L_081D693E(c);
    queue_panel_environment(-1);
}

static unsigned selected_chapter;
static int practice_started;
static unsigned mouse_grab_buttons(unsigned buttons)
{
    uint32_t mgr = rd32(PLAYER_MANAGER);
    int caught = mgr && (rd32(mgr + 0x68) || rd32(mgr + 0x88) || rd32(mgr + 0x90));
    int shake = host_mouse_shake(caught);
    if (caught && shake >= 0) {
        unsigned reload=host_solo_player()?CAB_P2_RELOAD:CAB_P1_RELOAD;
        unsigned firemode=host_solo_player()?CAB_P2_FIREMODE:CAB_P1_FIREMODE;
        buttons &= ~(reload|firemode);
        if (shake) buttons |= reload;
    }
    return buttons;
}

static SDL_atomic_t practice_restart;
extern int host_hotd4_restart_key(int key);
extern void host_special_practice_ready(void);
void L_08214544(CPU *c);
static void h_practice_stage(CPU *c)
{
    uint32_t game=A32(0),marker=0,saved=0;
    if (!practice_started && rd32(game+0x38)==7) {
        unsigned stage=selected_chapter+6;
        uint32_t table=rd32(0x084c2e70u+stage*4),markers=rd32(table+4);
        for(unsigned i=0;i<rd32(table+8);i++)if(rd32(markers+i*8)==2){marker=markers+i*8+4;break;}
        if(!marker){fprintf(stderr,"[practice] missing Special chapter entry\n");exit(1);}
        saved=rd32(marker);wr32(marker,0);
        wr32(game+0x38,stage);wr32(game+0x3c,0);practice_started=1;host_special_practice_ready();
        fprintf(stderr,"[practice] Special chapter %u\n",selected_chapter);
    }
    push32(c,rd32(c->esp-4));L_08214544(c);
    if(marker)wr32(marker,saved);
}
static int SDLCALL practice_key(void *unused,SDL_Event *event)
{
    (void)unused;
#if !defined(LINDBERGH_OPENXR)
    if(event->type==SDL_KEYDOWN && !event->key.repeat && host_hotd4_restart_key(event->key.keysym.sym))
        SDL_AtomicSet(&practice_restart,1);
#endif
    return 1;
}

static uint32_t event_command(uint32_t self)
{
    return rd32(rd32(self + 0x34) + 8);
}

/* The second chapter's first part is stored before the opening's script.
 * Include it when handling live cinema bars, fullscreen movies and Start. */
static int story_command(uint32_t command)
{
    return (command >= STAGE_TWO_BEGIN && command < STAGE_TWO_INTRO_END) ||
           (command >= OPENING_MOVIE_END && command < STORY_EVENTS_END);
}

/* EventSkip walks commands until a resume or scene-change command. Early
 * exit at the script terminator would leave the game with no next event. */
static int has_cutscene_exit(uint32_t cmd)
{
    while (cmd <= STORY_EVENTS_END - 8) {
        uint32_t op = rd32(cmd), words = rd32(cmd + 4);
        if (op == 0x26 || op == 0x3a) return 1;
        if (op <= 3 || op > 0xa3 || words > (STORY_EVENTS_END - cmd - 8) / 4) return 0;
        cmd += 8 + words * 4;
    }
    return 0;
}

/* Sofdec's two slots can be decoding a movie without drawing it. Use the
 * same fullscreen draw states as CSofdecMgr::Draw. */
static int fullscreen_movie_visible(void)
{
    uint32_t mgr = rd32(SOFDEC_MANAGER);
    if (!mgr) return 0;
    for (uint32_t slot = mgr + 0x34; slot < mgr + 0x1bc; slot += 0xc4) {
        if (!rd32(slot)) continue;
        uint32_t mode = rd32(slot + 4);
        if (mode == 3 || (mode == 1 && rd32(slot + 8))) return 1;
    }
    return 0;
}

static void h_event_main(CPU *c)
{
    static int previous_start;
    static uint32_t pending_boss_state;
    uint32_t self = A32(0);
    int start = (host_cabinet_buttons() & CAB_P1_START) != 0;
    uint32_t command = event_command(self);
    uint32_t ret = rd32(c->esp - 4);
    uint32_t player = rd32(PLAYER_MANAGER);
    int hold = player && rd32(player + 0x54);
    int native_skip = player && rd32(player + 0x58);
    int intro = command >= OPENING_FIRST_WAIT && command < OPENING_MOVIE_END;
    int story = story_command(command);
    uint32_t state = rd32(self + 0x34);
    if (pending_boss_state != state || !hold || command < BOSS_RIDE_CHANGE || command >= BOSS_SCENE_END)
        pending_boss_state = 0;
    /* The native skip stops at the ride change. Let the interpreter run
     * that command, then finish the same Hold Your Fire scene. */
    int resume_boss_skip = pending_boss_state && command > BOSS_RIDE_CHANGE;
    int pressed = start && !previous_start;
    if ((pressed || resume_boss_skip) && !native_skip && (intro || (story && hold)) && has_cutscene_exit(command)) {
        CPU event = *c;
        event.eax = self;
        event.edx = 3;  /* same argument as the cabinet's Start handler */
        if (guest_call(&event, EVENT_SKIP, NULL, 0)) {
            uint32_t next = event_command(self);
            pending_boss_state = next == BOSS_RIDE_CHANGE ? state : 0;
            fprintf(stderr, "[hotd4sp] cutscene skipped (%08x -> %08x)\n", command, next);
        }
    }
    previous_start = start;
    push32(c, ret);
    L_0813B58C(c);
    command = event_command(self);
    player = rd32(PLAYER_MANAGER);
    int story_bars = (command >= OPENING_BEGIN && command < OPENING_HOLD_END) ||
                     (story_command(command) && player && rd32(player + 0x54));
    int movie = (command >= OPENING_BEGIN && command < OPENING_MOVIE_END) ||
                (story_bars && fullscreen_movie_visible());
    stereo_wide_preserve_frame(movie);
    stereo_wide_story_bars(story_bars);
    /* Leave the title, results and Game Over background intact. */
    stereo_wide_blackout_suppression(story_command(command) ||
                                    (command >= OPENING_BEGIN && command < STORY_EVENTS_END));
    stereo_wide_path_choice(player && rd32(player + 0x5c));
#if !defined(LINDBERGH_OPENXR)
    if(selected_chapter || getenv("HOTD4SP_MENU")) {
        static int watching;
        if(!watching){SDL_AddEventWatch(practice_key,NULL);watching=1;}
        if(SDL_AtomicGet(&practice_restart))exit(74);
    }
#endif

}

/* Correct the primary, reversed and assist rays before the native routine
 * normalizes them and turns them into world space. */
static void h_aim_normalize(CPU *c)
{
    uint32_t ret = rd32(c->esp - 4);
    float k;
    if ((ret == 0x0806a5afu || ret == 0x0806a5f0u || ret == 0x0806a631u) &&
        stereo_wide(NULL, NULL, &k) && !stereo_flat_frame()) {
        float *camera_ray = APTR(1);
        camera_ray[0] /= k;
    }
    push32(c, ret);
    L_082F7494(c);
}

static void install_desktop_hooks(void)
{
    for (unsigned i = 0; i < HLE_COUNT; ++i) {
        if (!g_hle_handlers[i]) continue;
        const char *name = hle_name((HleId)i);
        if (!strcmp(name, "glGetIntegerv")) {
            original_get_integer = g_hle_handlers[i];
            g_hle_handlers[i] = h_get_integer;
            host_use_guest_viewport_coords();

        }
    }
}
#endif

#if defined(_WIN32)
/* Verified against the supported Special dump, not normal HOTD4 offsets. */
void L_0817984A(CPU *c); /* CGunMgr::MainProc(INPUT_SET *, unsigned char) */
void L_08193C9C(CPU *c); /* CPlayer::ReloadProc; magazine is this+0x2d4 */
void L_080B9F46(CPU *c); /* CBloodEffect constructor, original emitter table */
void L_08214934(CPU *c); /* CFrameRateMgr::Init0 */

static void h_gun_input(CPU *c)
{
    uint32_t input=c->edx,player=c->ecx&0xff;
    push32(c,rd32(c->esp-4));L_0817984A(c);
    if(player<2){
        unsigned b=host_cabinet_buttons();
        int reload=(b & (player?CAB_P2_RELOAD:CAB_P1_RELOAD))!=0;
        int shake=(b & (player?(CAB_P2_RELOAD|CAB_P2_FIREMODE):(CAB_P1_RELOAD|CAB_P1_FIREMODE)))!=0;
        wr32(input+0x0c,reload);
        /* Special's JVS path reads P1's shake bit for both players. Route
         * their shake/reload independently, including a guest mouse as P2. */
        wr32(input+0x14,shake);wrss(input+0x1c,shake?3.0f:0.0f);
        /* CPlayer's input gate (08191F31..08191F89) opens on trigger or
         * grenade, but ignores shake. Justice can grab before either was
         * pressed, leaving SwingProc unreachable even with valid gyro input.
         * Treat an actual shake during a grab as that player's first input.
         * Native SwingProc still applies its timing, strength and resistance. */
        uint32_t mgr=rd32(PLAYER_MANAGER),game=rd32(0x0a69f8d4u);
        if(shake && mgr && game && rd32(game+0x34)==9 &&
           (rd32(mgr+0x68)||rd32(mgr+0x88)||rd32(mgr+0x90))){
            uint32_t pl=rd32(mgr+0x34+4*player);
            if(pl && rd8(pl+0x34)==player && rd32(pl+0x38)==3 && !rd32(pl+0x270))wr32(pl+0x270,1);
        }
    }
}
static void h_reload(CPU *c)
{
    uint32_t self=c->eax,pl=rd8(self+0x34),manager=rd32(0x0a69f934u),trigger=0,saved=0;
    int mx,my,w,h;host_mouse_state(&mx,&my,NULL);
    if((pl^host_solo_player())==1 && !host_gun2_state(&mx,&my))mx=my=-100000;
    lindbergh_window_size(&w,&h);
    if(pl<2 && manager && (mx<0 || my<0 || mx>=w || my>=h)){
        trigger=manager+0x3c+pl*36;saved=rd32(trigger);wr32(trigger,1);
    }
    /* Special normally auto-reloads on trigger release. Preserve that on
     * screen; off screen, require the chosen trigger/reload policy. */
    push32(c,rd32(c->esp-4));L_08193C9C(c);
    if(trigger)wr32(trigger,saved);
}
static void h_blood(CPU *c)
{
    uint32_t args=c->esp,type=rd32(args+12),scale_bits=rd32(args+24),self=rd32(args);
    int enhanced=gameplay_blood_splatter() && type==1;
    if(enhanced){
        float scale;memcpy(&scale,&scale_bits,4);
        if(isfinite(scale) && scale>0 && scale<=8){scale*=1.25f;uint32_t v;memcpy(&v,&scale,4);wr32(args+24,v);}
        wr32(args+12,2);
    }
    push32(c,rd32(args-4));L_080B9F46(c);
    if(enhanced){wr32(args+12,type);wr32(args+24,scale_bits);}
    static int log=-1;if(log<0){const char*v=getenv("LINDBERGH_BLOOD_LOG");log=v&&!strcmp(v,"1");}
    if(log){extern unsigned g_frame;fprintf(stderr,"[blood] Special frame %u original %u selected %u active %u\n",g_frame,type,enhanced?2:type,rd32(self+0x78));}
}
static void h_frame_rate(CPU *c)
{
    uint32_t manager=rd32(c->esp);
    push32(c,rd32(c->esp-4));L_08214934(c);
    int cinema=rd32(manager)==0 && rd32(manager+0x20)==1 && rd32(manager+0x54)==10;
    if(cinema)wr32(manager+0x54,1);
    host_pace_fps(cinema?30:0);
    fprintf(stderr,"[hotd4sp] frame pacing: %s\n",cinema?"original 30 Hz cutscene":"gameplay / original timing");
}
static void install_shared_hooks(void)
{
    for(unsigned i=0;i<HLE_COUNT;i++)if(g_hle_handlers[i]&&!strcmp(hle_name((HleId)i),"fread")){
        original_fread=g_hle_handlers[i];g_hle_handlers[i]=h_read_without_wipe;break;
    }
    guest_override_va("Special event interpreter",EVENT_MAIN,h_event_main);
    guest_override_va("Special gun reload routing",0x0817984au,h_gun_input);
    guest_override_va("Special off-screen reload",0x08193c9cu,h_reload);
    guest_override_va("Special blood effects",0x080b9f46u,h_blood);
    const char *pace=getenv("LINDBERGH_HOTD4_PACE_CUTSCENES"),*unpaced=getenv("LINDBERGH_UNPACED");
    if(!(pace && !strcmp(pace,"0")) && !(unpaced && atoi(unpaced)))
        guest_override_va("Special cutscene pacing",0x08214934u,h_frame_rate);
}
#endif

/* The gun, where the game reads it: GetAdjstGunPos(&x, &y, rawx, rawy,
 * adjust, ...) turns the board's raw words into a byte each, 0..255 across
 * the screen, through the stored calibration. A mouse needs no calibration,
 * so this answers from the pointer, as games/hotd4 does. Register arguments:
 * eax = &x, edx = &y. Outside the window the gun is off the screen. */
static void h_gun_pos(CPU *c)
{
    /* the stack: raw x, raw y, adjust, player - player 2's gun (dual
     * wielding) answers from the second pointer, not the first */
    uint32_t player = rd32(c->esp + 20);
    int mx, my, w, h;
    if ((player ^ host_solo_player()) == 1) { if (!host_gun2_state(&mx, &my)) mx = my = -100000; }
    else host_mouse_state(&mx, &my, NULL);
    lindbergh_window_size(&w, &h);
    int on = mx >= 0 && my >= 0 && mx < w && my < h;
#if defined(_WIN32) && !defined(LINDBERGH_OPENXR) && !defined(LINDBERGH_VULKAN)
    float k;
    uint32_t manager = rd32(PLAYER_MANAGER);
    int path_choice = manager && rd32(manager + 0x5c);
    if (on && stereo_wide(NULL, NULL, &k) && (stereo_flat_frame() || path_choice)) {
        mx = (int)lroundf((mx - (w - 1) * 0.5f) / k + (w - 1) * 0.5f);
        on = mx >= 0 && mx < w;
    }
#endif
    long x = ((long)mx * 255 + (w - 1) / 2) / (w > 1 ? w - 1 : 1),
         y = ((long)my * 255 + (h - 1) / 2) / (h > 1 ? h - 1 : 1);
    wr8(c->eax, (uint8_t)(x < 0 ? 0 : x > 255 ? 255 : x));
    wr8(c->edx, (uint8_t)(y < 0 ? 0 : y > 255 ? 255 : y));
    c->eax = on;
}

/* The keychip's second check. Starting a game, the Special has the keychip
 * decrypt a 1 KB block of its own (0x084BA7E0) under a fresh random IV and
 * compares the result with the plaintext it carries (0x084BABE0); a match is
 * a licensed board, anything else is "Error 15 - Game Program Not Found". The
 * cryptography lives in the keychip, so for that one request this answers
 * what a genuine one would, and fails anything else as no keychip does.
 * Arguments: iv, iv, in, out, length. */
#define KEY_CHALLENGE  0x084ba7e0u
#define KEY_EXPECTED   0x084babe0u
#define KEY_CRYPT      0x08363fd7u      /* the keychip library's block decrypt */
static void h_key_crypt(CPU *c)
{
    if (A32(2) == KEY_CHALLENGE && A32(4) == 0x400) {
        memcpy(APTR(3), GP(KEY_EXPECTED), 0x400);
        RET(0);
        return;
    }
    RET(-5);
}

/* LINDBERGH_GOD=1: the player takes no damage, for test runs that must reach
 * a later scene. CPlayer::CanDamagePlayer() - matched against the original
 * game's, the same code with the player's fields moved - answers no. */
#define CAN_DAMAGE_PLAYER 0x080c18d4u
static void h_no_damage(CPU *c) { RET(0); }

/* In the headset the shot leaves the gun, not the head. The game aims its
 * shot along a ray from its camera through the gun's point on the screen -
 * CPlayer::GetTarget(), matched against the original game's, fills the
 * player's ray: the camera's position (this+0x274) and the direction in the
 * world (+0x284) and the camera's space (+0x294). Player 1's is put on the
 * gun's own ray, turned into the world by the game's camera, so the shot -
 * and the splash where it lands - follows the laser at every distance. */
#define GET_TARGET        0x0806a306u
#define GET_CAM_MATRIX    0x0818ddc0u   /* CamCtrlMgr_GetCamMatrix(KfMatrixNNGL *) - eax */
#define MATRIX_NO_MOVE    0x082f4640u   /* KfUnitMatrixTranslation(KfMatrixNNGL *) */
#define INVERT_MATRIX     0x0833305cu   /* nnInvertMatrix(out, in) */
#define CALC_POINT        0x082f4e0au   /* KfCalcPoint(out, matrix, in) */
void L_0806A306(CPU *c);
static uint32_t g_shot_buf;             /* guest memory: a matrix and two vectors */
static void h_get_target(CPU *c)
{
    uint32_t ret = rd32(c->esp - 4);          /* dispatch took the return address off */
    uint32_t self = c->eax;
    push32(c, ret);
    L_0806A306(c);
    uint32_t ok = c->eax;
    float go[3], gd[3];
    uint32_t pos = A32(3), dir = A32(4), cdir = A32(7);
    unsigned player = rd8(self + 0x34);      /* each player fires from their own gun (dual wielding) */
    int have = player < 2 && stereo_gun_ray((int)player, go, gd);
    if (player == 0) {   /* LINDBERGH_TEST_RAY=ox,oy,oz,dx,dy,dz: a fixed ray, camera space (testing off the headset) */
        const char *t = getenv("LINDBERGH_TEST_RAY");
        if (t && sscanf(t, "%f,%f,%f,%f,%f,%f", &go[0], &go[1], &go[2], &gd[0], &gd[1], &gd[2]) == 6) have = 1;
    }
    static int dbg = -1;
    if (dbg < 0) dbg = getenv("LINDBERGH_AIM_LOG") != NULL;
    if (dbg) { static unsigned k; if (++k % 120 == 1) fprintf(stderr, "[hotd4sp] GetTarget: player %u, ok %u, ray %d\n", rd8(self + 0x34), ok, have); }
    if (!ok || !pos || !dir || !have) { c->eax = ok; return; }
    if (!g_shot_buf) g_shot_buf = H2G(guest_alloc(64 + 32, 16));
    uint32_t m = g_shot_buf, vin = m + 64, vout = m + 80;
    /* the camera's turn into the world, as GetTarget makes it */
    c->eax = m;
    if (!guest_call(c, GET_CAM_MATRIX, NULL, 0)) { c->eax = ok; return; }
    { uint32_t a[1] = { m }; guest_call(c, MATRIX_NO_MOVE, a, 1); }
    { uint32_t a[2] = { m, m }; guest_call(c, INVERT_MATRIX, a, 2); }
    float n = sqrtf(gd[0] * gd[0] + gd[1] * gd[1] + gd[2] * gd[2]);
    if (!(n > 0)) { c->eax = ok; return; }
    for (int i = 0; i < 3; i++) gd[i] /= n;
    float wo[3], wd[3];
    const float *in[2] = { go, gd };
    float *out[2] = { wo, wd };
    for (int k = 0; k < 2; k++) {
        float *v = (float *)GP(vin);
        v[0] = in[k][0]; v[1] = in[k][1]; v[2] = in[k][2]; v[3] = 1;
        uint32_t a[3] = { vout, m, vin };
        guest_call(c, CALC_POINT, a, 3);
        memcpy(out[k], GP(vout), 12);
    }
    float *p = (float *)GP(pos), *d = (float *)GP(dir);
    for (int i = 0; i < 3; i++) { p[i] += wo[i]; d[i] = wd[i]; }
    if (cdir) { float *cd = (float *)GP(cdir); cd[0] = gd[0]; cd[1] = gd[1]; cd[2] = gd[2]; }
    static int log = -1;
    if (log < 0) { const char *v = getenv("LINDBERGH_AIM_LOG"); log = v && *v == '1'; }
    if (log) { static unsigned k; if (++k % 60 == 1)
        fprintf(stderr, "[hotd4sp] shot from the gun: camera-space o %.2f %.2f %.2f d %.3f %.3f %.3f -> world d %.3f %.3f %.3f\n",
                go[0], go[1], go[2], gd[0], gd[1], gd[2], wd[0], wd[1], wd[2]); }
    c->eax = ok;
}

/* What the runtime needs to know about this game (game_profile.h). */
static const LgGameProfile k_profile = {
    .title = "The House of the Dead 4 Special",
#if defined(_WIN32) && !defined(LINDBERGH_OPENXR) && !defined(LINDBERGH_VULKAN)
    // The ride prompts, gameplay HUD and video fades share a 1024x768 canvas.
    .width = 1024, .height = 768,
#else
    .width = 1360, .height = 768,
#endif
    .aim = { 1, 0, 1, 0 },
    .solo_characters = 2, /* shared ride Start/credits; selectable gun seat */
    /* the seats: turned, shaken and blown at by a board on the first serial port */
    .ride_board = "/dev/ttyS0",
    /* its language follows the region in the EEPROM's system data */
    .sysdata_region = 1,
    /* a shake of the gun (its reload) is the second switch byte's bit 6 */
    .reload_switch = { 1, 0x40 },
    .vr = {
        .gun_model = XO_GUN_TP9,    /* a B&T TP9 in the player's hand */
        .title = "The House of the Dead 4 Special VR",
        /* its path choice tests the gun against 1024x768: at 640x480 a shot
         * on the right box lands between the two */
        .width = 1024, .height = 768,
        .scale = 1,
        .depth_read = LG_DEPTH_AUTO,
        .gl_thread = 1,         /* the street: 32-37 fps with the GL on the game's thread, 56-58 without */
        .hud_head_locked = 1,   /* the life bar and prompts where the eye expects them, wherever it looks */
        /* its shots leave the gun (h_get_target), so its screen point only places
         * its 2D - the hit's splash among it: where the laser crosses the HUD */
        .aim_on_hud = 1,
        /* its 2D - HUD, subtitles, the path choice's boxes - is quads hung
         * before a 45-degree, 4:3 camera of its own (the world's is 1.954) */
        .hud_lens = 1.8107f,
    },
};

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr,
            "usage: %s <hod4M.elf> [game args...]\n"
            "\n"
            "  hod4M.elf is The House of the Dead 4 Special's executable, from a game\n"
            "  tree you can already read. None of it ships here - see the README.\n",
            argv[0]);
        return 2;
    }

    guest_install_crash_handler();
    if (guest_load(argv[1], argc - 1, argv + 1) != 0)
        return 1;
    game_profile_apply(&k_profile);
#if defined(_WIN32) && !defined(LINDBERGH_OPENXR) && !defined(LINDBERGH_VULKAN)
    const HostSettings *video = settings();
    int height = video->window_h > 0 ? video->window_h : 1080;
    int width = video->window_w > 0 ? video->window_w : 1920;
    const char *render_size=getenv("HOTD4SP_RENDER_SIZE");
    int rw,rh;char extra;
    if(render_size && sscanf(render_size,"%dx%d%c",&rw,&rh,&extra)==2 && rw>=640 && rh>=360 && rw<=8192 && rh<=8192) {
        width=rw;height=rh;
    }
    if ((int64_t)width * 9 < (int64_t)height * 16) height = (int)((int64_t)width * 9 / 16);
    if (height > 0) stereo_wide_default((int)((int64_t)height * 16 / 9), height, k_profile.vr.hud_lens);
#endif
    gameplay_options_load();
    hle_register_all();
#ifdef _WIN32
    install_shared_hooks();
#endif
#if defined(_WIN32) && !defined(LINDBERGH_OPENXR) && !defined(LINDBERGH_VULKAN)
    install_desktop_hooks();
    const char *chapter=getenv("HOTD4SP_CHAPTER");
    if(chapter && (chapter[0]=='1'||chapter[0]=='2') && !chapter[1]) {
        selected_chapter=(unsigned)(chapter[0]-'0');
        guest_override_va("Special chapter select",0x08214544u,h_practice_stage);
    }
    host_cabinet_button_filter(mouse_grab_buttons);
    guest_override_va("CellSprite player panel", PANEL_SPRITE_DRAW, h_hud_group_draw);
    guest_override_va("CEnvMgr::RenderEnv", 0x081d693eu, h_panel_environment);
    if (stereo_wide(NULL, NULL, NULL))
        guest_override_va("shot ray normalization", AIM_NORMALIZE, h_aim_normalize);
#endif
    /* Same NN side-plane builder as HOTD4. The stripped supported build reads
     * focal lengths at A6F34C0/A6F34D4 and writes four planes at A6F3468.
     * Like HOTD4, enclose the wider eye/head view without changing its render
     * projection. LINDBERGH_CULL_WIDEN=1 restores the cabinet control. */
    float cull_widen = nn_culling_default_widen();
#if defined(_WIN32) && !defined(LINDBERGH_OPENXR) && !defined(LINDBERGH_VULKAN)
    float wide_scale;
    if (stereo_wide(NULL, NULL, &wide_scale)) cull_widen = 1.0f / wide_scale;
#endif
    nn_culling_install("nnSetClipPlane", 0x08346aa0u, 0x0a6f34c0u, 0x0a6f34d4u, cull_widen);

    guest_override_va("keychip decrypt", KEY_CRYPT, h_key_crypt);
    {
        const char *g = getenv("LINDBERGH_GOD");
        if (g && *g == '1' && guest_override_va("CPlayer::CanDamagePlayer", CAN_DAMAGE_PLAYER, h_no_damage))
            fprintf(stderr, "[hotd4sp] the player takes no damage (LINDBERGH_GOD)\n");
    }
    {   /* the headset's; LINDBERGH_SHOT_FROM_GUN=0 from the head, as the game has it, =1 off it too */
        const char *v = getenv("LINDBERGH_SHOT_FROM_GUN");
#ifdef __ANDROID__
        int on = !(v && *v == '0');
#else
        int on = v && *v == '1';
#endif
        if (on && guest_override_va("CPlayer::GetTarget", GET_TARGET, h_get_target))
            fprintf(stderr, "[hotd4sp] the shot leaves the gun\n");
    }
    if (guest_override("_Z14GetAdjstGunPosPhS_ttP18GunAdjustValueTypei", h_gun_pos))
        fprintf(stderr, "[hotd4sp] aim: the gun is where the pointer is\n");

    CPU cpu;
    guest_init_cpu(&cpu);
    dispatch(&cpu, guest_entry());

    fprintf(stderr, "[host] the entry point returned - _start should not.\n");
    return 1;
}
