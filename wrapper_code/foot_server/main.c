#include <sys/wait.h>
#include <unistd.h>

static char arg0[] = "/usr/bin/foot";
static char arg1[] = "--server";
static char *const args[3] = {arg0, arg1, NULL};

void forker() {
  pid_t pid = fork();
  if (pid == 0) {
    execv(arg0, args);
  } else {
    waitpid(pid, NULL, 0);
  }
}

int main() {
  while (1) {
    forker();
  }
  return 1;
}
