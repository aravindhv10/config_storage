#include <fcntl.h>
#include <semaphore.h>
#include <stdio.h>

int main(int const argc, char const **argv) {
  sem_t *sem = sem_open("/testing", /*int oflag =*/O_CREAT, 0700, 2);
  if (sem != SEM_FAILED) {
    printf("Successfully opened the semaphor\n");
  }
}
