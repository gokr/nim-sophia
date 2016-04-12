#ifndef SOPHIA_H_
#define SOPHIA_H_


#ifdef C2NIM
#  dynlib libname
#  cdecl
#  prefix sp_
#  if defined(windows)
#    define libname "libsophia.dll"
#  elif defined(macosx)
#    define libname "libsophia.dylib"
#  else
#    define libname "libsophia.so"
#  endif
#mangle uint16_t uint16
#mangle uint64_t uint64
#mangle int64_t int64
#endif

/*
 * sophia database
 * sphia.org
 *
 * Copyright (c) Dmitry Simonenko
 * BSD License
*/

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>
#include <stdint.h>

 void    *sp_env(void);
 void    *sp_document(void*);
 int      sp_setstring(void*, const char*, const void*, int);
 int      sp_setint(void*, const char*, int64_t);
 void    *sp_getobject(void*, const char*);
 void    *sp_getstring(void*, const char*, int*);
 int64_t  sp_getint(void*, const char*);
 int      sp_open(void*);
 int      sp_destroy(void*);
 int      sp_error(void*);
 int      sp_service(void*);
 void    *sp_poll(void*);
 int      sp_drop(void*);
 int      sp_set(void*, void*);
 int      sp_upsert(void*, void*);
 int      sp_delete(void*, void*);
 void    *sp_get(void*, void*);
 void    *sp_cursor(void*);
 void    *sp_begin(void*);
 int      sp_prepare(void*);
 int      sp_commit(void*);

#ifdef __cplusplus
}
#endif

#endif
