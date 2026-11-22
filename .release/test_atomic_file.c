#define _POSIX_C_SOURCE 200809L
#include <assert.h>
#include <stdlib.h>
#include "../source/lindberghrecomp/src/runtime/atomic_file.h"
#ifndef _WIN32
#include <sys/wait.h>
#endif
static void check(const char *path,const char *expected)
{
    char value[128]={0};FILE *f=fopen(path,"rb");assert(f);
    size_t n=fread(value,1,sizeof value,f);fclose(f);
    assert(n==strlen(expected) && !memcmp(value,expected,n));
}
int main(int argc,char **argv)
{
    assert(argc>=2);
    const char *path=argv[argc-1];LgAtomicFile file;
    if(argc==3 && !strcmp(argv[1],"interrupted")){
        assert(lg_atomic_file_begin(&file,path));
        assert(fwrite("incomplete",1,10,file.stream)==10);fflush(file.stream);
        _exit(0); /* no commit: simulate a process killed during a save */
    }
    for(int i=0;i<20;i++){
        const char *value=i%2?"previous valid save":"complete replacement";
        assert(lg_atomic_file_begin(&file,path));assert(fwrite(value,1,strlen(value),file.stream)==strlen(value));
        assert(lg_atomic_file_commit(&file));check(path,value);
    }
#ifdef _WIN32
    assert(_spawnl(_P_WAIT,argv[0],argv[0],"interrupted",path,(char *)NULL)==0);
#else
    pid_t child=fork();assert(child>=0);
    if(!child)execl(argv[0],argv[0],"interrupted",path,(char *)NULL);
    int status;assert(waitpid(child,&status,0)==child && WIFEXITED(status) && WEXITSTATUS(status)==0);
#endif
    check(path,"previous valid save");
    assert(lg_atomic_file_begin(&file,path));fputs("aborted",file.stream);lg_atomic_file_abort(&file);
    check(path,"previous valid save");
    remove(path);puts("Atomic save: complete replacement, abort and interrupted writer preserved the previous save.");return 0;
}
