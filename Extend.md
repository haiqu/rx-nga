````
/* c-rx.c, copyright (c) 2016 charles childers */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "c-rx.c"



void read_token(FILE *file, char *token_buffer) {
  if (file == NULL)
  {
    printf("Error: file pointer is null.");
    exit(1);
  }
  char ch = getc(file);
  int count = 0;
  if (ch == '\'') {
    token_buffer[count++] = ch;
    ch = getc(file);
    while ((ch != '\'') && (ch != EOF))
    {
      token_buffer[count++] = ch;
      ch = getc(file);
    }
  } else {
    while ((ch != '\n') && (ch != ' ') && (ch != EOF))
    {
      token_buffer[count++] = ch;
      ch = getc(file);
    }
  }
  token_buffer[count] = '\0';
}

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

  FILE *fp;
  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }
  fwrite(&memory, sizeof(CELL), Heap, fp);
  fclose(fp);

  return 0;
}
````
