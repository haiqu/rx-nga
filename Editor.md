# Editor

Classic Forth systems often had a *block editor* for storing code. This is an interface layer for Rx built around this concept.

## Implementation Overview

Blocks are 512 cells in length. They are displayed as 8 rows with 64 cells per row.

This editor is a hybrid implementation. Blocks are stored in the image memory and Rx code is used to control the active block, input point, and insertion of code. The C code in this interface layer provides the *view* and *evaluation* of code.

The implementation also takes some hints from VIBE, a VI inspired Block Editor fom Sam Falvo II. It uses the Rx dictionary to provide key handlers. This makes it possible to extend the interactions beyond the standard set without rebuilding everything.

    :red:command-27 #1 &red:Mode store ;
    :red:insert-27 #0 &red:Mode store ;

The **-27** is the ASCII value for the key (ESC in this case). The **red:command** prefix is for the command mode version; the **red:insert** prefix for entry time remapping of the keys to actions.

## Standard Headers

````
#include <stdio.h>
#include <stdlib.h>
````

## Rx &amp; Nga

````
#include "c-rx.c"
````

## Terminal

This interface assumes a VT100-style terminal emulation. The interface is wrapped into a few simple functions. The default is to use *termios* and *ioctl*, though this limits portability. It'd be better to use *curses* instead, but that's a little more complex. Maybe at a later time...

````
#include <termios.h>
#include <sys/ioctl.h>

struct termios new_termios, old_termios;
````

Setup and restoration of the terminal environment. To work properly we need:

* non-buffered input
* no keyboard echo

The **term_setup()** turns these on while **term_cleanup()** resets to the prior state.

````
void term_setup() {
  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag |= (IGNBRK+IGNPAR);
  new_termios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  new_termios.c_cc[VMIN] = 1;
  new_termios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &new_termios);
}

void term_cleanup() {
  tcsetattr(0, TCSANOW, &old_termios);
}
````

````
void term_clear() {
  printf("\033[2J\033[1;1H");
}

void term_move_cursor(int x, int y) {
  printf("\033[%d;%dH", y, x);
}
````

````
CELL Current;
CELL Column;
CELL Row;

void update_internals() {
  update_rx();
  Current = memory[d_xt_for("red:Current", Dictionary)];
  Column = memory[d_xt_for("red:Col", Dictionary)];
  Row = memory[d_xt_for("red:Row", Dictionary)];
}

int get_index() {
  CELL index;
  update_internals();
  index = memory[d_xt_for("red:index", Dictionary)];
  execute(index);
  return stack_pop();
}
````


````
char blocks[1024*4096];
int mode;
int block, col, row;

void block_display(int n) {
  for (int i = 0; i < 8; i++)
    printf("--------");
  printf(" #%d", n);
  int line = 0;
  int start = n * 512;
  while (line < 8) {
    printf("\n");
    for (int i = 0; i < 64; i++)
      printf("%c", blocks[start + i]);
    start += 64;
    line++;
  }
  printf("\n");
  for (int i = 0; i < 8; i++)
    printf("--------");
  printf(" %d:%d %c\n", col, row, (mode ? 'i' : 'c'));
}
void bounds() {
  if (col < 0)
    col = 0;
  if (col > 63)
    col = 63;
  if (row < 0)
    row = 0;
  if (row > 7)
    row = 7;
}
void red_save() {
  FILE *fd;
  fd = fopen("blockfile", "w");
  for (int i = 0; i < (512*4096); i++)
    fprintf(fd, "%c", blocks[i]);
  fclose(fd);
}
void red_enter(int ch) {
  blocks[(block * 512)+col+(row * 64)] = ch;
  col++;
}
void display_stack() {
  for (CELL i = 1; i <= sp; i++) {
    if (i == sp)
      printf("< %d >", data[i]);
    else
      printf("%d ", data[i]);
  }
  printf("\n");
}
int next_token(int offset, char *token_buffer) {
  int end = offset;
  int count = 0;
  char ch = blocks[(block *512) + end];
  end++;
  while ((ch != ' ') && (end < 512))
  {
    token_buffer[count++] = ch;
    ch = blocks[(block * 512) + end];
    end++;
  }
  token_buffer[count] = '\0';
  return end;
}
void evaluate_block() {
  char source[512];
  int offset = 0;
  while (offset < 512)
  {
    offset = next_token(offset, source);
    evaluate(source);
  }
}
int main() {
  FILE *fp;
  fp = fopen("blockfile", "r");
  for (int i = 0; i < (4096*512); i++)
    blocks[i] = 32;
  if (fp == NULL)
    return -1;
  int i = 0;
  while (!feof(fp))
  {
    blocks[i++] = getc(fp);
  }
  fclose(fp);
  col = 0;
  row = 0;
  mode = 0;
  term_setup();
  ngaPrepare();
  ngaLoadImage("ngaImage");
  update_rx();
  block = 0;
  int ch;
  while (1) {
    update_rx();
    term_clear();
    block_display(block);
    printf("%d Free, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE - Heap, TIB, Heap);
    printf("\ni up | j left | k down | l right | n next | p prev | \\ mode | q quit | e eval");
    display_stack();
    term_move_cursor(col + 1, row + 2);
    ch = getchar();
    if (mode == 0) {
      switch ((char)ch) {
        case 'q': term_move_cursor(1, 15); term_cleanup(); exit(0); break;
        case 'n': block++; break;
        case 'p': block--; break;
        case 'i': row--; break;
        case 'j': col--; break;
        case 'k': row++; break;
        case 'l': col++; break;
        case 'e': evaluate_block(); break;
        case '\\': mode = 1; break;
      }
    } else {
      switch ((char)ch) {
        case '\\': mode = 0; red_save(); break;
        case  8:
        case 127: col--; break;
        case 10:
        case 13: ch = 32;
        default: red_enter(ch); break;
      }
    }
    bounds();
    if (block > 4096) block = 4096;
    if (block < 0) block = 0;
  }
  return 0;
}
````
