#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static char proc_self_exe[] = "/proc/self/exe";
static size_t const len_proc_self_exe =
    (sizeof(proc_self_exe) / sizeof(char)) - 1;

static char name_ld[] = "/ld-linux-x86-64.so.2";
static size_t const len_name_ld = (sizeof(name_ld) / sizeof(char)) - 1;

static char library_path[] = "--library-path";
static size_t const len_library_path =
    (sizeof(library_path) / sizeof(char)) - 1;

static char argv0[] = "--argv0";
static size_t const len_argv0 = (sizeof(argv0) / sizeof(char)) - 1;

static inline size_t align(size_t val) {
  size_t newval = val & (~7);
  if (newval == val) {
    return val;
  } else {
    return newval + 8;
  }
}

#define SIZE_BUFFER (1 << 22)

static char BUFFER[SIZE_BUFFER];
static int BUFFER_CURRENT;

static inline char *myalloc(size_t const insize) {
  BUFFER_CURRENT = align(BUFFER_CURRENT);
  char *ret = BUFFER + BUFFER_CURRENT;
  BUFFER_CURRENT += align(insize);
  return ret;
}

static inline char *get_prefix_dir() {

  char *ptr = BUFFER + BUFFER_CURRENT;

  ssize_t const tmp = readlink(/*const char *restrict pathname =*/proc_self_exe,
                               /*char *restrict buf =*/ptr,
                               /*size_t bufsiz =*/SIZE_BUFFER - BUFFER_CURRENT);

  ptr[tmp] = 0;

  char *c = ptr + tmp - 1;

  while (*c != '/') {
    --c;
  }

  *c = 0;

  while (*c != '/') {
    --c;
  }

  c[1] = 'e';
  c[2] = 'x';
  c[3] = 'e';
  c[4] = 0;

  c += 5;

  unsigned int const len = align(c - ptr);
  BUFFER_CURRENT += len;

  return ptr;
}

static inline char *get_ld(char const *path_dir_prefix) {
  /* size_t const len_name_ld = strlen(name_ld); */

  size_t const len_path_dir_prefix = strlen(path_dir_prefix);

  char *ret =
      (char *)myalloc((len_path_dir_prefix + len_name_ld + 1) * sizeof(char));

  memcpy(/*void *dest =*/ret, /*const void *src =*/path_dir_prefix,
         /*size_t n =*/len_path_dir_prefix);

  memcpy(/*void *dest =*/ret + len_path_dir_prefix,
         /*const void *src =*/name_ld,
         /*size_t n =*/len_name_ld);

  ret[len_path_dir_prefix + len_name_ld] = 0;

  return ret;
}

static inline char *get_name_exe(char *path_dir_prefix, char *name_exe) {
  size_t len_name_exe = strlen(name_exe);
  size_t len_path_dir_prefix = strlen(path_dir_prefix);
  char *ret = myalloc((len_name_exe + len_path_dir_prefix + 2) * sizeof(char));

  memcpy(/*void *dest =*/ret, /*const void *src =*/path_dir_prefix,
         /*size_t n =*/len_path_dir_prefix);

  ret[len_path_dir_prefix] = '/';

  memcpy(/*void *dest =*/ret + len_path_dir_prefix + 1,
         /*const void *src =*/name_exe,
         /*size_t n =*/len_name_exe);

  ret[len_path_dir_prefix + len_name_exe + 1] = 0;

  return ret;
}

static inline char *get_name(char *in) {
  char *ret = strrchr(/*const char *s =*/in, /*int c =*/'/');
  if (ret == NULL) {
    ret = in;
  } else {
    ret = ret + 1;
  }
  return ret;
}

int main(int const argc, char **argv) {
  BUFFER_CURRENT = 0;

  char *path_dir_prefix = get_prefix_dir();
  char *name_exe = get_name(/*char const * in =*/argv[0]);
  char *path_file_ld = get_ld(/*char const *path_dir_prefix =*/path_dir_prefix);
  char **final_args = (char **)myalloc((argc + 6) * sizeof(char *));

  final_args[0] = path_file_ld;
  final_args[1] = library_path;
  final_args[2] = path_dir_prefix;
  final_args[3] = argv0;
  final_args[4] = argv[0];
  final_args[5] = get_name_exe(/*char *path_dir_prefix =*/path_dir_prefix,
                               /*char *name_exe =*/name_exe);

  final_args[argc + 5] = NULL;
  for (int i = 1; i < argc; i++) {
    final_args[5 + i] = argv[i];
  }

  int ret = execv(/*const char *pathname =*/final_args[0],
                  /*char *const argv[] =*/final_args);

  printf("failed to run... %d\n", ret);

  for (int i = 0; i < argc + 3; ++i) {
    printf("%s\n", final_args[i]);
  }

  return ret;
}

#undef SIZE_BUFFER
