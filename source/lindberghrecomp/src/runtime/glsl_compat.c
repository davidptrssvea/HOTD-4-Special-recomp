#include <ctype.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "glsl_compat.h"

static int ident(unsigned char c) { return isalnum(c) || c == '_'; }
static const char *space(const char *p) { while (isspace((unsigned char)*p)) p++; return p; }
static int equal(const char *p, size_t n, const char *s) { return strlen(s) == n && !memcmp(p, s, n); }
static void copy(char **out, const char *p, size_t n) { memcpy(*out, p, n); *out += n; }
static const char *call_end(const char *p)
{
    int depth = 0;
    do { if (*p == '(') depth++; if (*p == ')') depth--; p++; } while (*p && depth);
    return depth ? NULL : p;
}
static const char *opaque(const char *p)
{
    if (*p == '#' || (p[0] == '/' && p[1] == '/')) {
        const char *end = strchr(p, '\n'); return end ? end : p + strlen(p);
    }
    if (p[0] == '/' && p[1] == '*') {
        const char *end = strstr(p + 2, "*/"); return end ? end + 2 : p + strlen(p);
    }
    return p;
}

char *glsl_compat(const char *source)
{
    size_t len = strlen(source);
    if (len > (SIZE_MAX - 64) / 4) return NULL;
    char *half = malloc(2 * len + 1), *result = malloc(4 * len + 64);
    if (!half || !result) { free(half); free(result); return NULL; }
    char *w = half;
    for (const char *p = source; *p;) {
        const char *end = opaque(p);
        if (end != p) { copy(&w, p, end - p); p = end; continue; }
        if (isalpha((unsigned char)*p) || *p == '_') {
            end = p + 1; while (ident((unsigned char)*end)) end++;
            size_t n = end - p;
            const char *replace = equal(p, n, "half") ? "float" :
                                  equal(p, n, "half2") ? "vec2" :
                                  equal(p, n, "half3") ? "vec3" :
                                  equal(p, n, "half4") ? "vec4" : NULL;
            if (replace) copy(&w, replace, strlen(replace)); else copy(&w, p, n);
            p = end;
        } else *w++ = *p++;
    }
    *w = 0; w = result;
    int scope = 0, parens = 0;
    for (const char *p = half; *p;) {
        const char *end = opaque(p);
        if (end != p) { copy(&w, p, end - p); p = end; continue; }
        if (!isalpha((unsigned char)*p) && *p != '_') {
            if (*p == '{') scope++; else if (*p == '}') scope--;
            else if (*p == '(') parens++; else if (*p == ')') parens--;
            *w++ = *p++; continue;
        }
        end = p + 1; while (ident((unsigned char)*end)) end++;
        size_t n = end - p;
        if (!scope && !parens && n > 7 && !memcmp(p, "sampler", 7)) {
            const char *prev_end = p;
            while (prev_end > half && isspace((unsigned char)prev_end[-1])) prev_end--;
            const char *prev = prev_end;
            while (prev > half && ident((unsigned char)prev[-1])) prev--;
            if (!equal(prev, prev_end - prev, "uniform")) copy(&w, "uniform ", 8);
        }
        /* Cg/NVIDIA accepts a numeric tuple as dot's vector operand, and
         * truncates the other vector to that width. Standard GLSL treats
         * the tuple as a scalar comma expression instead. */
        if (equal(p, n, "dot") && *space(end) == '(') {
            const char *lhs = space(space(end) + 1), *comma = lhs;
            while (ident((unsigned char)*comma) || *comma == '.') comma++;
            const char *sep = space(comma);
            if (*sep == ',' && *space(sep + 1) == '(') {
                const char *tuple = space(sep + 1), *at = tuple + 1;
                int lanes = 0;
                while (lanes < 4) {
                    char *e; strtod(space(at), &e);
                    if (e == space(at)) break;
                    lanes++; at = space(e);
                    if (*at != ',') break;
                    at++;
                }
                if (lanes >= 2 && *at == ')' && *space(at + 1) == ')') {
                    char type[] = "vec2"; type[3] = (char)('0' + lanes);
                    copy(&w, "dot(", 4); copy(&w, type, 4); *w++ = '(';
                    copy(&w, lhs, comma - lhs); copy(&w, "),", 2);
                    copy(&w, type, 4); *w++ = '(';
                    copy(&w, tuple + 1, at - tuple - 1); copy(&w, "))", 2);
                    p = space(at + 1) + 1; continue;
                }
            }
        }
        /* A scalar dot result assigned to a vector swizzle is broadcast. */
        if (*end == '.') {
            const char *sw = end + 1, *se = sw;
            while (*se && strchr("rgbaxyzw", *se)) se++;
            const char *eq = space(se);
            const char *rhs = *eq == '=' && eq[1] != '=' ? space(eq + 1) : eq;
            if (se - sw >= 2 && se - sw <= 4 && !strncmp(rhs, "dot", 3) && *space(rhs + 3) == '(') {
                const char *ce = call_end(space(rhs + 3));
                if (ce && *space(ce) == ';') {
                    char type[] = "vec2"; type[3] = (char)('0' + (se - sw));
                    copy(&w, p, rhs - p); copy(&w, type, 4); *w++ = '(';
                    copy(&w, rhs, ce - rhs); *w++ = ')'; p = ce; continue;
                }
            }
        }
        int vector = n == 4 && !memcmp(p, "vec", 3) && p[3] >= '2' && p[3] <= '4';
        int scalar = equal(p, n, "float");
        int matrix = n == 4 && !memcmp(p, "mat", 3) && p[3] >= '2' && p[3] <= '4';
        const char *name = space(end), *eq = name;
        if (isalpha((unsigned char)*eq) || *eq == '_') {
            while (ident((unsigned char)*eq)) eq++;
            eq = space(eq);
            if ((vector || scalar || matrix) && *eq == '=' && eq[1] != '=') {
                const char *rhs = space(eq + 1);
                if (matrix && *rhs == '{') {
                    const char *me = rhs; int depth = 0;
                    do { if (*me == '{') depth++; if (*me == '}') depth--; me++; } while (*me && depth);
                    if (!depth && *space(me) == ';') {
                        copy(&w, p, rhs - p); copy(&w, p, n); *w++ = '(';
                        for (const char *v = rhs + 1; v < me - 1; v++) *w++ = (*v == '{' || *v == '}') ? ' ' : *v;
                        *w++ = ')'; p = me; continue;
                    }
                } else if (vector) {
                    char *number_end;
                    strtod(rhs, &number_end);
                    if (number_end != rhs) {
                        if (*number_end == 'f' || *number_end == 'F') number_end++;
                        if (*space(number_end) == ';') {
                            copy(&w, p, rhs - p); copy(&w, p, n); *w++ = '(';
                            copy(&w, rhs, number_end - rhs); *w++ = ')';
                            p = number_end; continue;
                        }
                    }
                } else if (!strncmp(rhs, "shadow2D", 8) && *space(rhs + 8) == '(') {
                    const char *ce = call_end(space(rhs + 8));
                    if (ce && *space(ce) == ';') {
                        copy(&w, p, ce - p); copy(&w, ".r", 2);
                        p = ce; continue;
                    }
                }
            }
        }
        copy(&w, p, n); p = end;
    }
    *w = 0; free(half); return result;
}

#ifdef HOTD4SP_SHADER_COMPAT
/* Special supplies matrix indices through the legacy floating-point vertex
 * attribute API. Keep the original attribute name for binding and expose
 * integer components to the shader's matrix-palette calculations. */
char *glsl_compat_hotd4sp_vertex(const char *source)
{
    static const char alias[] = "\n#define nnglaMtxIdx (ivec4(nnglaMtxIdx))\n";
    if (!strstr(source, "NNGLD_OPT_VERTEX_BLEND")) return NULL;

    for (const char *p = source; *p;) {
        const char *token_end = opaque(p);
        if (token_end != p) { p = token_end; continue; }
        if (!ident((unsigned char)*p)) { p++; continue; }
        token_end = p + 1;
        while (ident((unsigned char)*token_end)) token_end++;
        const int attribute = equal(p, (size_t)(token_end - p), "attribute");
        p = token_end;
        if (!attribute) continue;

        const char *type = space(token_end);
        if (type == token_end || strncmp(type, "ivec4", 5)) continue;
        const char *name = space(type + 5);
        if (name == type + 5 || strncmp(name, "nnglaMtxIdx", 11)) continue;
        const char *end = space(name + 11);
        if (*end != ';') continue;
        end++;

        char *fixed = malloc(strlen(source) + sizeof alias);
        if (!fixed) return NULL;
        char *out = fixed;
        copy(&out, source, (size_t)(type - source));
        copy(&out, type + 1, (size_t)(end - type - 1));
        /* GLSL, like C, suppresses expansion of a macro's own name in its
         * replacement list. The constructor reads the attribute declared above. */
        copy(&out, alias, sizeof alias - 1);
        strcpy(out, end);
        return fixed;
    }
    return NULL;
}

/* The original depth-of-field shader calls shadow2D with a regular sampler. */
static char *special_depth_shader(const char *source)
{
    if (!strstr(source, "OrigPic") || !strstr(source, "BlurPic") || !strstr(source, "shadow2D"))
        return NULL;

    const char *decl = source;
    while ((decl = strstr(decl, "uniform")) != NULL) {
        decl += sizeof "uniform" - 1;
        const char *type = space(decl);
        if (type == decl || strncmp(type, "sampler2D", sizeof "sampler2D" - 1)) continue;

        const char *end = type + sizeof "sampler2D" - 1;
        const char *name = space(end);
        if (name == end || strncmp(name, "OrigDepth", sizeof "OrigDepth" - 1) ||
            *space(name + sizeof "OrigDepth" - 1) != ';') continue;

        char *fixed = malloc(strlen(source) + sizeof "Shadow");
        if (!fixed) return NULL;
        char *out = fixed;
        copy(&out, source, (size_t)(end - source));
        copy(&out, "Shadow", sizeof "Shadow" - 1);
        strcpy(out, end);
        return fixed;
    }
    return NULL;
}

/* Some fragment shaders offset texture coordinates. Keep the varying inputs
 * read-only and have the engine's coordinate macros use writable copies. */
static char *special_coord_shader(const char *source)
{
    static const char *const inputs[] = {
        "nnglvTexCoord01.xy", "nnglvTexCoord01.zw", "nnglvTexCoord23.xy", "nnglvTexCoord23.zw",
        "nnglvTexCoord45.xy", "nnglvTexCoord45.zw", "nnglvTexCoord67.xy", "nnglvTexCoord67.zw"
    };
    static const char copies[] =
        "vec4 g_nnglvTexCoord01 = nnglvTexCoord01;\n"
        "vec4 g_nnglvTexCoord23 = nnglvTexCoord23;\n"
        "vec4 g_nnglvTexCoord45 = nnglvTexCoord45;\n"
        "vec4 g_nnglvTexCoord67 = nnglvTexCoord67;\n";
    if (!strstr(source, "varying vec4 nnglvTexCoord01;")) return NULL;

    char macro[] = "#define nnglvTexCoord0";
    const char *first = strstr(source, macro);
    if (!first) return NULL;

    const char *at = first;
    const char *values[sizeof inputs / sizeof inputs[0]];
    for (size_t i = 0; i < sizeof inputs / sizeof inputs[0]; i++) {
        macro[sizeof macro - 2] = (char)('0' + i);
        if (strncmp(at, macro, sizeof macro - 1)) return NULL;
        const char *start = at + sizeof macro - 1;
        const char *value = space(start);
        size_t len = strlen(inputs[i]);
        if (value == start || strncmp(value, inputs[i], len)) return NULL;
        const char *next = value + len;
        if (*next != ' ' && *next != '\t' && *next != '\r' && *next != '\n') return NULL;
        at = strchr(next, '\n');
        if (!at) return NULL;
        at = space(at + 1);
        values[i] = value;
    }

    char *fixed = malloc(strlen(source) + sizeof copies + 2 * (sizeof inputs / sizeof inputs[0]));
    if (!fixed) return NULL;
    char *out = fixed;
    copy(&out, source, (size_t)(first - source));
    copy(&out, copies, sizeof copies - 1);
    const char *rest = first;
    for (size_t i = 0; i < sizeof inputs / sizeof inputs[0]; i++) {
        copy(&out, rest, (size_t)(values[i] - rest));
        copy(&out, "g_", 2);
        rest = values[i];
    }
    strcpy(out, rest);
    return fixed;
}

char *glsl_compat_hotd4sp(const char *source)
{
    char *fixed = special_coord_shader(source);
    return fixed ? fixed : special_depth_shader(source);
}
#endif
