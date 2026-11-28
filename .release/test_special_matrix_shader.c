#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../source/lindberghrecomp/src/runtime/glsl_compat.h"

/* Synthetic skinning shader, without game assets. Matrix indices arrive via
 * the legacy floating-point attribute API used by Special. */
static const char vertex[] =
    "#version 120\n"
    "#define NNGLD_OPT_VERTEX_BLEND 1\n"
    "attribute ivec4 nnglaMtxIdx;\n"
    "attribute vec4 nnglaWeights;\n"
    "uniform vec4 palette[8];\n"
    "void main() {\n"
    "gl_FrontColor=palette[nnglaMtxIdx.x]*nnglaWeights.x"
    "+palette[nnglaMtxIdx.y]*nnglaWeights.y"
    "+palette[nnglaMtxIdx.z]*nnglaWeights.z"
    "+palette[nnglaMtxIdx.w]*nnglaWeights.w;\n"
    "gl_Position=vec4(0.0,0.0,0.0,1.0);\n"
    "}\n";

static void test_scope(void)
{
    const char *untouched[] = {
        "#version 120\nattribute ivec4 nnglaMtxIdx;\nvoid main(){}\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\nattribute vec4 nnglaMtxIdx;\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\nattribute ivec4 anotherIndex;\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\nattribute ivec4 nnglaMtxIdxExtra;\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\nattribute ivec4x nnglaMtxIdx;\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\n// attribute ivec4 nnglaMtxIdx;\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\n/* attribute ivec4 nnglaMtxIdx; */\n",
        "#define NNGLD_OPT_VERTEX_BLEND 1\n#define COMMENT attribute ivec4 nnglaMtxIdx;\n"
    };
    for (size_t i=0; i<sizeof untouched/sizeof untouched[0]; ++i)
        assert(glsl_compat_hotd4sp_vertex(untouched[i])==NULL);
    char *fixed=glsl_compat_hotd4sp_vertex(vertex);
    assert(fixed);
    assert(!strncmp(fixed,"#version 120\n",13));
    assert(strstr(fixed,"attribute vec4 nnglaMtxIdx;"));
    assert(strstr(fixed,"palette[nnglaMtxIdx.x]*nnglaWeights.x"));
    assert(strstr(fixed,"attribute vec4 nnglaWeights;"));
    assert(glsl_compat_hotd4sp_vertex(fixed)==NULL);
    free(fixed);
    fixed=glsl_compat_hotd4sp_vertex(
        "#define NNGLD_OPT_VERTEX_BLEND 1\nattribute\tivec4\n nnglaMtxIdx \t;\n");
    assert(fixed);
    free(fixed);
}

#ifdef HOTD_SHADER_GPU_TEST
#define SDL_MAIN_HANDLED
#include <GL/glew.h>
#include <SDL2/SDL.h>
#include <math.h>

static GLuint compile(GLenum type,const char *source)
{
    GLuint sh=glCreateShader(type);
    glShaderSource(sh,1,&source,NULL);
    glCompileShader(sh);
    GLint ok=0;glGetShaderiv(sh,GL_COMPILE_STATUS,&ok);
    if (!ok) {
        char log[4096];glGetShaderInfoLog(sh,sizeof log,NULL,log);
        fprintf(stderr,"%s\n",log);
        exit(1);
    }
    return sh;
}

static void test_gpu(void)
{
    SDL_SetMainReady();
    assert(SDL_Init(SDL_INIT_VIDEO)==0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION,2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION,1);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER,0);
    SDL_Window *window=SDL_CreateWindow("Matrix shader test",0,0,1,1,
                                      SDL_WINDOW_OPENGL|SDL_WINDOW_HIDDEN);
    assert(window);
    SDL_GLContext context=SDL_GL_CreateContext(window);
    assert(context && glewInit()==GLEW_OK);
    while (glGetError()!=GL_NO_ERROR) {}
    printf("OpenGL: %s\n",glGetString(GL_RENDERER));
    char *fixed=glsl_compat_hotd4sp_vertex(vertex);
    assert(fixed);
    GLuint vs=compile(GL_VERTEX_SHADER,fixed);
    GLuint fs=compile(GL_FRAGMENT_SHADER,"#version 120\nvoid main(){gl_FragColor=gl_Color;}\n");
    GLuint p=glCreateProgram();
    glAttachShader(p,vs);glAttachShader(p,fs);
    glBindAttribLocation(p,4,"nnglaMtxIdx");
    glBindAttribLocation(p,5,"nnglaWeights");
    glLinkProgram(p);
    GLint linked=0;glGetProgramiv(p,GL_LINK_STATUS,&linked);
    assert(linked);
    assert(glGetAttribLocation(p,"nnglaMtxIdx")==4);
    glUseProgram(p);
    float palette[8][4];
    for (int i=0;i<8;i++) {
        palette[i][0]=(i+1)/8.0f;palette[i][1]=(8-i)/8.0f;
        palette[i][2]=(i%3)/2.0f;palette[i][3]=1.0f;
    }
    glUniform4fv(glGetUniformLocation(p,"palette[0]"),8,&palette[0][0]);
    GLuint texture,fb;
    glGenTextures(1,&texture);glBindTexture(GL_TEXTURE_2D,texture);
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,1,1,0,GL_RGBA,GL_UNSIGNED_BYTE,NULL);
    glGenFramebuffers(1,&fb);glBindFramebuffer(GL_FRAMEBUFFER,fb);
    glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,texture,0);
    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER)==GL_FRAMEBUFFER_COMPLETE);
    glViewport(0,0,1,1);
    glDisable(GL_DITHER);glDisable(GL_BLEND);glDisable(GL_DEPTH_TEST);
    const float weights[4]={0.1f,0.2f,0.3f,0.4f};
    glVertexAttrib4fv(5,weights);
    const float indices[3][4]={{0,2,4,6},{1,3,5,7},{0,7,1,4}};
    const unsigned char bytes[4]={1,3,5,7};
    for (int test=0;test<3;test++) {
        glDisableVertexAttribArray(4);
        if (test==0) glVertexAttrib4fv(4,indices[test]);
        else {
            glVertexAttribPointer(4,4,test==1?GL_UNSIGNED_BYTE:GL_FLOAT,GL_FALSE,0,
                                  test==1?(const void *)bytes:(const void *)indices[test]);
            glEnableVertexAttribArray(4);
        }
        glClearColor(0,0,0,0);glClear(GL_COLOR_BUFFER_BIT);
        glDrawArrays(GL_POINTS,0,1);
        unsigned char pixel[4];glReadPixels(0,0,1,1,GL_RGBA,GL_UNSIGNED_BYTE,pixel);
        assert(glGetError()==GL_NO_ERROR);
        for (int channel=0;channel<4;channel++) {
            float expected=0;
            for (int k=0;k<4;k++) expected+=weights[k]*palette[(int)indices[test][k]][channel];
            assert(fabsf(pixel[channel]-255.0f*expected)<=2.0f);
        }
    }
    glDeleteFramebuffers(1,&fb);glDeleteTextures(1,&texture);
    glDeleteProgram(p);glDeleteShader(vs);glDeleteShader(fs);
    free(fixed);
    SDL_GL_DeleteContext(context);SDL_DestroyWindow(window);SDL_Quit();
    puts("PASS GPU palette addressing with legacy float/byte attributes and four blend weights");
}
#endif

int main(void)
{
    test_scope();
#ifdef HOTD_SHADER_GPU_TEST
    test_gpu();
#endif
    puts("PASS Special matrix-index compatibility scope, attribute binding and idempotence");
    return 0;
}
