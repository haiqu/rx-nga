# Listener

This is a fairly simple Retro style interactive interface for Rx.

## Legalities

Just a quick copyright notice.

````
/* listener, copyright (c) 2016 charles childers */
````

## Headers

````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
````

## Include C-Rx API

````
#include "c-rx.c"
````

##

````
void read_token(FILE *file, char *token_buffer) {
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
  printf("+ load %s\n", fname);
  while (!feof(fp))
  {
    read_token(fp, source);
    evaluate(source);
  }
  fclose(fp);
}
````

````
void dump_stack() {
  printf("Stack: ");
  for (CELL i = 1; i <= sp; i++) {
    if (i == sp)
      printf("< %d >", data[i]);
    else
      printf("%d ", data[i]);
  }
  printf("\n");
}

void prompt() {
  if (memory[Compiler] == 0)
    printf(" ok  ");
}

int main(int argc, char **argv) {
  printf("rx-2016.10 [C-Rx Listener]\n");
  ngaPrepare();
  ngaLoadImage("ngaImage");
  update_rx();
  printf("%d MAX, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE, TIB, Heap);
  char input[1024];
  include_file("startup.rx");
  while(1) {
    prompt();
    Dictionary = memory[2];
    read_token(stdin, input);
    if (strcmp(input, "bye") == 0)
      exit(0);
    else if (strcmp(input, "words") == 0) {
      CELL i = Dictionary;
      while (i != 0) {
        string_extract(d_name(i));
        printf("%s  ", string_data);
        i = memory[i];
      }
      printf("(%d entries)\n", d_count_entries(Dictionary));
    }
    else if (strcmp(input, ".s") == 0) {
      dump_stack();
    }
    else
      evaluate(input);
  }
  exit(0);
}
````
