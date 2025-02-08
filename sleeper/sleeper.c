#include <stdio.h>
#include <unistd.h>

int main() {
  pid_t mypid;
  FILE *f;
  unsigned int ret;
  mypid = getpid();
  while (1) {
    f = fopen("pid", "w");
    fprintf(f, "%u", mypid);
    fclose(f);
    ret = sleep(0xFFFFFFFF);
  }
}
