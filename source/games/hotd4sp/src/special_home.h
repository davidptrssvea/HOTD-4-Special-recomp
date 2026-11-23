/* The attraction sends damage to the whole cabinet. In Home mode each hit
 * costs one life to a participating seat, alternating between eligible seats.
 * The native damage path still handles hit effects, invulnerability and the
 * final Game Over. These rules operate on the supported Special arcade ELF. */
enum { HOME_START_LIVES = 3 };
static unsigned home_lives[2], home_players, home_next_hit;
static int home_active;
static SDL_atomic_t home_hud;

void L_080C1396(CPU *c);
void L_0819B506(CPU *c);
void L_08088AFC(CPU *c);
void L_08088EFE(CPU *c);

static int home_update(uint32_t manager)
{
    uint32_t game = rd32(GAME_MANAGER);
    if (!manager || !game || rd32(game + 0x34) != 9) {
        home_active = 0;
        return 0;
    }
    unsigned primary = (unsigned)host_solo_player();
    if (!home_active) {
        home_players = 1u << primary;
        home_lives[primary] = HOME_START_LIVES;
        home_lives[primary ^ 1] = 0;
        home_next_hit = primary;
        home_active = 1;
    }
    if (host_gun2_state(NULL, NULL) && home_players != 3) {
        home_lives[primary ^ 1] = HOME_START_LIVES;
        home_players = 3;
    }
    return 1;
}

static int home_hud_snapshot(void)
{
    return (int)((home_players << 4) | (home_lives[1] << 2) | home_lives[0]);
}

static void h_home_damage(CPU *c)
{
    uint32_t ret = rd32(c->esp - 4);
    uint32_t manager = c->eax;
    if (manager != rd32(PLAYER_MANAGER) || !home_update(manager)) {
        push32(c, ret);
        L_080C1396(c);
        return;
    }

    unsigned target = home_next_hit;
    uint32_t player[2] = {rd32(manager + 0x34), rd32(manager + 0x38)};
    if (!home_lives[target] || !player[target] || rd32(player[target] + 0x38) != 3) target ^= 1;
    if (!home_lives[target] || !player[target] || !player[target ^ 1]) {
        RET(0);
        return;
    }

    uint32_t other_state = player[target ^ 1] + 0x38;
    uint32_t saved_state = rd32(other_state);
    uint32_t health = manager + 0x40;
    uint32_t saved_health = rd32(health);
    unsigned remaining = home_lives[0] + home_lives[1];
    /* Exclude the other seat from native damage and hit reactions. Pass a
     * lethal native health value only for the last life across both seats. */
    wr32(other_state, 0);
    wr32(health, remaining == 1 ? 1 : 100);
    push32(c, ret);
    L_080C1396(c);
    int hit = c->eax && rd32(health) != (remaining == 1 ? 1u : 100u);
    wr32(other_state, hit && remaining == 1 && saved_state ? 10u : saved_state);
    if (!hit) {
        wr32(health, saved_health);
        return;
    }

    --home_lives[target];
    home_next_hit = target ^ 1;
    if (remaining > 1) {
        unsigned capacity = HOME_START_LIVES * (home_players == 3 ? 2 : 1);
        unsigned max_life = rd32(manager + 0x3c);
        unsigned life = (max_life * (remaining - 1) + capacity - 1) / capacity;
        wr32(health, life ? life : 1);
    }
}

static void h_home_life_sprite(CPU *c)
{
    uint32_t ret = rd32(c->esp - 4);
    /* The two draw calls are the shared life label and gauge. */
    if (ret == 0x0819b4f0u || ret == 0x0819b4ffu) return;
    push32(c, ret);
    L_0819B506(c);
}

static void h_home_ride_turn(CPU *c)
{
    uint32_t controller = A32(0);
    push32(c, rd32(c->esp - 4));
    L_08088AFC(c);
    unsigned state = rd32(controller + 0x34);
    /* The ride controller changes view between the wipe's closing and
     * reopening phases, even on a cabinet with the motor switched off. */
    StereoRidePhase phase = STEREO_RIDE_IDLE;
    if (home_active && state)
        phase = state == 1 || state == 4 ? STEREO_RIDE_CLOSING : STEREO_RIDE_OPENING;
    stereo_wide_ride_view(phase);
}

static void h_home_ride_wipe(CPU *c)
{
    if (home_active && stereo_wide(NULL, NULL, NULL) && !stereo_flat_frame()) return;
    push32(c, rd32(c->esp - 4));
    L_08088EFE(c);
}

static void home_draw_lives(int x, int y, int w, int h)
{
    unsigned snapshot = (unsigned)SDL_AtomicGet(&home_hud);
    if (!snapshot || w <= 0 || h <= 0) return;
    GLint mode, program, unit;
    glGetIntegerv(GL_MATRIX_MODE, &mode);
    glGetIntegerv(GL_CURRENT_PROGRAM, &program);
    glGetIntegerv(GL_ACTIVE_TEXTURE, &unit);
    glPushAttrib(GL_ALL_ATTRIB_BITS);
    glUseProgram(0);
    glDisable(GL_VERTEX_PROGRAM_ARB);
    glDisable(GL_FRAGMENT_PROGRAM_ARB);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    glDisable(GL_LIGHTING);
    glDisable(GL_FOG);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    GLint units;
    glGetIntegerv(GL_MAX_TEXTURE_UNITS, &units);
    for (int i = 0; i < units; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        glDisable(GL_TEXTURE_CUBE_MAP);
    }
    glViewport(x, y, w, h);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, w, 0, h, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    float hud_scale = hud_custom_scale();
    float size = h * (hud_scale > 0 ? hud_scale : 1) / 60;
    for (unsigned seat = 0; seat < 2; ++seat) {
        if (!(snapshot & (16u << seat))) continue;
        unsigned lives = (snapshot >> (2 * seat)) & 3u;
        float left = seat ? w - 6.3f * size : 2.1f * size;
        for (unsigned i = 0; i < HOME_START_LIVES; ++i) {
            float bx = left + i * size * 1.4f;
            float by = size * 2.8f;
            glColor3f(0.05f, 0.06f, 0.09f);
            glRectf(bx, by, bx + 1.2f * size, by + size);
            if (i < lives) {
                if (seat) glColor3f(1.0f, 0.44f, 0.40f);
                else glColor3f(0.30f, 0.82f, 1.0f);
            } else glColor3f(0.31f, 0.32f, 0.36f);
            glRectf(bx + 0.12f * size, by + 0.12f * size,
                    bx + 1.08f * size, by + 0.88f * size);
        }
    }
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode((GLenum)mode);
    glPopAttrib();
    glActiveTexture((GLenum)unit);
    glUseProgram((GLuint)program);
}
