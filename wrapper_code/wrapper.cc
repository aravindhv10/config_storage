#include "cstdlib"
#include "stdio.h"
#include "stdlib.h"
#include "string"
#include "string.h"
#include "unistd.h"
#include <cstdio>

inline void start_program(std::string exe_name, int const argc, char **argv) {

  using type_primitive_string = char *;
  std::string home_dir("/home/asd/");
  std::string exe_dir(home_dir + "exe/");
  std::string main_exe_path(exe_dir + exe_name);
  std::string ld_file_path(exe_dir + "ld-linux-x86-64.so.2");

  char library_path[] = "--library-path";

  int const memsize = (argc + 4) * sizeof(type_primitive_string);
  type_primitive_string *next_args =
      static_cast<type_primitive_string *>(malloc(memsize));

  next_args[0] = &(ld_file_path[0]);
  next_args[1] = library_path;
  next_args[2] = &(exe_dir[0]);
  next_args[3] = &(main_exe_path[0]);
  for (int i = 1; i < argc; i++) {
    next_args[3 + i] = argv[i];
  }
  next_args[argc + 3] = NULL;

  execv(/*const char *pathname =*/next_args[0],
        /*char *const argv[] =*/next_args);

  free(next_args);
}

int main(int const argc, char **argv) {

  start_program(/*std::string exe_name =*/"rg", /*int const argc =*/argc,
                /*char **argv =*/argv);

  return 0;
}
