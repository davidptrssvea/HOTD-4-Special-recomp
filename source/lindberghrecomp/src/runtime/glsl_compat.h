#ifndef GLSL_COMPAT_H
#define GLSL_COMPAT_H
/* NVIDIA's legacy scalar/vector and half syntax -> portable GLSL.
 * The caller owns the returned string. No game-specific substitutions. */
char *glsl_compat(const char *source);

#ifdef HOTD4SP_SHADER_COMPAT
/* Returns a corrected fragment shader, or NULL if no correction is needed. */
char *glsl_compat_hotd4sp(const char *source);
/* Restores the matrix-index vertex input used by the legacy vertex array. */
char *glsl_compat_hotd4sp_vertex(const char *source);
#endif
#endif
