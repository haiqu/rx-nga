# C-Rx Image Extender

````
/* c-rx.c, copyright (c) 2016 charles childers */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "c-rx.c"

void include_file(char *fname) {
  char source[64000];
  FILE *fp;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return;
  while (!feof(fp))
  {
    read_token(fp, source);
    evaluate(source);
  }
  fclose(fp);
}

int main(int argc, char **argv) {
  printf("rx-2016.10 [C-Rx Listener]\n");
  ngaPrepare();
  ngaLoadImage("ngaImage");
  update_rx();
  printf("%d MAX, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE, TIB, Heap);
  include_file("startup.rx");
  update_rx();
  printf("%d MAX, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE, TIB, Heap);

  FILE *fp;
  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }
  fwrite(&memory, sizeof(CELL), IMAGE_SIZE, fp);
  fclose(fp);

  return 0;
}
````
