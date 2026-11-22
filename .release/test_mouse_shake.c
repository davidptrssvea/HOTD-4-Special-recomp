#include <assert.h>
#include <stdio.h>
#include "../source/lindberghrecomp/src/runtime/mouse_shake.h"

int main(void)
{
    MouseShake s;
    mouse_shake_reset(&s);
    /* Aiming in one direction, including a long sweep, never struggles. */
    for (unsigned t = 10; t < 500; t += 10) mouse_shake_motion(&s, 40, 0, t);
    assert(!mouse_shake_pulse(&s, 500));
    /* Small alternating hand jitter must not count as a deliberate shake. */
    mouse_shake_reset(&s);
    for (unsigned t = 10; t < 500; t += 10) mouse_shake_motion(&s, t % 20 ? 2 : -2, 0, t);
    assert(!mouse_shake_pulse(&s, 500));
    for (int axis = 0; axis < 2; axis++) {
        mouse_shake_reset(&s);
        mouse_shake_motion(&s, axis ? 0 : 28, axis ? 28 : 0, 100);
        mouse_shake_motion(&s, axis ? 0 : -28, axis ? -28 : 0, 150);
        assert(!mouse_shake_pulse(&s, 150));
        mouse_shake_motion(&s, axis ? 0 : 28, axis ? 28 : 0, 200);
        assert(mouse_shake_pulse(&s, 200));
        assert(mouse_shake_pulse(&s, 239));
        assert(!mouse_shake_pulse(&s, 240));
        /* Very rapid turns cannot spam new pulses. */
        mouse_shake_motion(&s, axis ? 0 : -28, axis ? -28 : 0, 220);
        assert(s.pulses == 1);
        mouse_shake_motion(&s, axis ? 0 : 28, axis ? 28 : 0, 300);
        assert(s.pulses == 2 && mouse_shake_pulse(&s, 300));
        /* Leaving a grab, pausing or losing focus resets residual motion. */
        mouse_shake_reset(&s);
        assert(!mouse_shake_pulse(&s, 301));
    }
    mouse_shake_reset(&s);
    mouse_shake_motion(&s, 28, 0, 100);
    mouse_shake_motion(&s, -28, 0, 150);
    mouse_shake_motion(&s, 28, 0, 700);
    assert(!mouse_shake_pulse(&s, 700));
    /* SDL's millisecond clock wraps; an active pulse still expires. */
    mouse_shake_reset(&s);
    mouse_shake_motion(&s, 28, 0, UINT32_MAX - 100);
    mouse_shake_motion(&s, -28, 0, UINT32_MAX - 50);
    mouse_shake_motion(&s, 28, 0, UINT32_MAX - 10);
    assert(mouse_shake_pulse(&s, 5));
    assert(!mouse_shake_pulse(&s, 30));
    puts("Mouse shake: deliberate horizontal/vertical gestures, jitter, sweeps, timing, resets and clock wrap passed.");
    return 0;
}
