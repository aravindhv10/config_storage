#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define BUFFER_ALIGNMENT_POW 3
#define BUFFER_DIVISION_CHECK ((1 << BUFFER_ALIGNMENT_POW) - 1)
#define BUFFER_SIZE_POW 21
#define BUFFER_SIZE (1 << BUFFER_SIZE_POW << BUFFER_ALIGNMENT_POW)

static unsigned char BUFFER[BUFFER_SIZE];
static unsigned long BUFFER_CURRENT_POSITION = 0;

static inline unsigned char *BUFFER_GET_CURRENT_POSITION() {
  return BUFFER + (BUFFER_CURRENT_POSITION << BUFFER_ALIGNMENT_POW);
}

static inline unsigned char *BUFFER_ALLOC_POW(unsigned long const in) {
  unsigned char *ret = BUFFER_GET_CURRENT_POSITION();
  BUFFER_CURRENT_POSITION += in;
  return ret;
}

static inline unsigned char *BUFFER_ALLOC(unsigned long const in) {
  unsigned long const tmp = in >> BUFFER_ALIGNMENT_POW;
  if (in & BUFFER_DIVISION_CHECK) {
    return BUFFER_ALLOC_POW(tmp + 1);
  } else {
    return BUFFER_ALLOC_POW(tmp);
  }
}

static char *exe_path = "/usr/bin/g++";
static char *argvs[] = {"-Ofast", "-mtune=native", "-march=native"};

#define push(NAME)                                                             \
  argv_new[index] = NAME;                                                      \
  index += 1

char **get_argv(int const argc, char **argv) {
  int const total_size = argc + 4;

  char **argv_new = (char **)BUFFER_ALLOC(
      /*unsigned long const in =*/total_size * sizeof(char *));

  int index = 0;

  push(exe_path);
  push(argvs[0]);
  push(argvs[1]);
  push(argvs[2]);
  for (int i = 1; i < argc; ++i) {
    push(argv[i]);
  }
  push(NULL);

  return argv_new;
}

#undef push

int main(int const argc, char **argv) {
  char **argv_new = get_argv(/*int const argc =*/argc, /*char **argv =*/argv);
  int const ret = execvp(/*const char *file =*/argv_new[0],
                         /*char *const argv[] =*/argv_new);
  return ret;
}
