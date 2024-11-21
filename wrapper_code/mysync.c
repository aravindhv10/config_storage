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

static char *rsync_path = "/usr/bin/rsync";
static char *arg1 = "-avh";
static char *arg2 = "--progress";

int main(int const argc, char **argv) {
  int const total_size = argc + 3;

  char **argv_new = (char **)BUFFER_ALLOC(
      /*unsigned long const in =*/total_size * sizeof(char *));

  argv_new[0] = argv[0];
  argv_new[1] = arg1;
  argv_new[2] = arg2;
  argv_new[argc + 2] = NULL;

  for (int i = 1; i < argc; ++i) {
    argv_new[2 + i] = argv[i];
  }

  int ret = execvp(/*const char *file =*/rsync_path,
                   /*char *const argv[] =*/argv_new);

  return ret;
}
