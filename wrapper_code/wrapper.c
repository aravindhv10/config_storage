#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define SIZE_BUFFER 1 << 22
static char BUFFER[SIZE_BUFFER];

static char const proc_self_exe[] = "/proc/self/exe";
static char const name_ld[] = "/ld-linux-x86-64.so.2";
static char library_path[] = "--library-path";

char *get_ld(char const *path_dir_prefix) {
  size_t const len_name_ld = strlen(name_ld);

  size_t len_path_dir_prefix = strlen(path_dir_prefix);

  char *ret =
      (char *)malloc((len_path_dir_prefix + len_name_ld) * sizeof(char));

  memcpy(/*void *dest =*/ret, /*const void *src =*/path_dir_prefix,
         /*size_t n =*/len_path_dir_prefix);

  memcpy(/*void *dest =*/ret + len_path_dir_prefix,
         /*const void *src =*/name_ld,
         /*size_t n =*/len_name_ld);

  return ret;
}

char *get_name_exe(char *path_dir_prefix, char *name_exe) {
  size_t len_name_exe = strlen(name_exe);
  size_t len_path_dir_prefix = strlen(path_dir_prefix);
  char *ret = malloc((len_name_exe + len_path_dir_prefix + 1) * sizeof(char));

  memcpy(/*void *dest =*/ret, /*const void *src =*/path_dir_prefix,
         /*size_t n =*/len_path_dir_prefix);

  ret[len_path_dir_prefix] = '/';
  memcpy(/*void *dest =*/ret + len_path_dir_prefix + 1,
         /*const void *src =*/name_exe,
         /*size_t n =*/len_name_exe);

  return ret;
}

char *get_name(char *in) {
  char *ret = strrchr(/*const char *s =*/in, /*int c =*/'/');
  if (ret == NULL) {
    ret = in;
  } else {
    ret = ret + 1;
  }
  return ret;
}

char *get_prefix_dir() {
  ssize_t const tmp = readlink(/*const char *restrict pathname =*/proc_self_exe,
                               /*char *restrict buf =*/BUFFER,
                               /*size_t bufsiz =*/SIZE_BUFFER);
  BUFFER[tmp] = 0;
  char *c = BUFFER + tmp - 1;
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
  c = c + 4;
  unsigned int const len = c - BUFFER;
  char *ret = malloc(len);

  memcpy(/*void dest[restrict.n] =*/ret, /*const void src[restrict.n] =*/BUFFER,
         /*size_t n =*/len);

  return ret;
}

int main(int const argc, char **argv) {
  char *path_dir_prefix = get_prefix_dir();
  char *name_exe = get_name(/*char const * in =*/argv[0]);
  // char name_exe[] = "alacritty";
  char *path_file_ld = get_ld(/*char const *path_dir_prefix =*/path_dir_prefix);
  char **final_args = (char **)malloc((argc + 4) * sizeof(char *));

  final_args[0] = get_ld(/*char const *path_dir_prefix =*/path_dir_prefix);
  final_args[1] = library_path;
  final_args[2] = path_dir_prefix;
  final_args[3] = get_name_exe(/*char *path_dir_prefix =*/path_dir_prefix,
                               /*char *name_exe =*/name_exe);

  final_args[argc + 3] = NULL;
  for (int i = 1; i < argc; i++) {
    final_args[3 + i] = argv[i];
  }

  /* for (int i = 0; i < argc + 3; ++i) { */
  /*   printf("%s\n", final_args[i]); */
  /* } */

  int ret = execv(/*const char *pathname =*/final_args[0],
                  /*char *const argv[] =*/final_args);

  printf("failed to run... %d\n", ret);

  for (int i = 0; i < argc + 3; ++i) {
    printf("%s\n", final_args[i]);
  }

  free(final_args[3]);
  free(final_args);
  free(path_file_ld);
  free(path_dir_prefix);

  return ret;
}

#undef SIZE_BUFFER
