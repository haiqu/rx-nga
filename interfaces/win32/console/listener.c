/* listener, copyright (c) 2016 charles childers */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include "bridge.c"
#include <windows.h>

HANDLE hStdIn;
DWORD fdwMode, fdwOldMode;

void term_setup() {
  hStdIn = GetStdHandle(STD_INPUT_HANDLE);
  GetConsoleMode(hStdIn, &fdwOldMode);
  SetConsoleTitle("RETRO 12 - Windows");
  fdwMode = fdwOldMode ^ ENABLE_LINE_INPUT;
  SetConsoleMode(hStdIn, fdwMode);
}
void term_cleanup() {
  SetConsoleMode(hStdIn, fdwMode);
}
void term_clear() {
}
void term_move_cursor(int x, int y) {
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
    printf("\nok  ");
}
int main(int argc, char **argv) {
  ngaPrepare();
  ngaLoadImage("ngaImage");
  update_rx();
  printf("RETRO 12 (rx-%d.%d)\n", memory[4] / 100, memory[4] % 100);
  char input[1024];
//  include_file("retro.forth");
  term_setup();
  printf("%d MAX, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE, TIB, Heap);
  while(1) {
    prompt();
    Dictionary = memory[2];
    read_token(stdin, input);
    if (strcmp(input, "bye") == 0) {
      term_cleanup();
      exit(0);
    }
    else if (strcmp(input, "words") == 0) {
      CELL i = Dictionary;
      while (i != 0) {
        string_extract(d_name(i));
        printf("%s  ", string_data);
        i = memory[i];
      }
      printf("(%d entries)\n", d_count_entries(Dictionary));
    }
    else if (strcmp(input, ".p") == 0) {
      printf("__%s__", string_extract(data[sp]));
    }
    else if (strcmp(input, ".s") == 0) {
      dump_stack();
    }
    else
      evaluate(input);
  }
  term_cleanup();
  exit(0);
}
