#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

char *get_ld(char const *path_dir_prefix) {
  char name_ld[] = "/ld-linux-x86-64.so.2";
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

int main(int const argc, char **argv) {
  char path_dir_prefix[] = "/home/asd/exe";
  char library_path[] = "--library-path";
  char name_exe[] = "sk";
  char *path_file_ld = get_ld(/*char const *path_dir_prefix =*/path_dir_prefix);
  char **final_args = (char **)malloc((argc + 4) * sizeof(char *));
  final_args[0] = get_ld(/*char const *path_dir_prefix =*/path_dir_prefix);
  final_args[1] = library_path;
  final_args[2] = path_dir_prefix;
  final_args[3] = get_name_exe(/*char *path_dir_prefix =*/path_dir_prefix,
                               /*char *name_exe =*/name_exe);

  final_args[argc + 3] = NULL;
  for (size_t i = 1; i < argc; i++) {
    final_args[3 + i] = argv[i];
  }

  int ret = execv(/*const char *pathname =*/final_args[0],
                  /*char *const argv[] =*/final_args);

  printf("failed to run... %d\n", ret);

  free(final_args[3]);
  free(final_args);
  free(path_file_ld);

  return ret;
}
