# Retro Block Editor

This is one part of the Retro Block Editor. See *EditorForth.md* for the other portion.

The implementation is split into two parts: an *interface layer*, written in C, and the editor logic, which is written in Retro. The code here contains the interface layer.

## Implementation Overview

Blocks are 512 cells in length. They are displayed as 8 rows with 64 cells per row.

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

## Editor State

The editor state is handled by the Retro portion of the code. The interface layer does need to be aware of it though so this defines a few global variables and a function for keeping them in sync with the underlying code.

````
CELL Current;
CELL Column;
CELL Row;
CELL Mode;

void update_state() {
  update_rx();
  Current = memory[d_xt_for("red:Current", Dictionary)];
  Column = memory[d_xt_for("red:Col", Dictionary)];
  Row = memory[d_xt_for("red:Row", Dictionary)];
  Mode = memory[d_xt_for("red:Mode", Dictionary)];
}
````

## Display a Block

These functions are used to display a block.

````
void sep() {
  for (int i = 0; i < 8; i++)
    printf("--------");
  printf("\n");
}

void row(int block, int n) {
  int start = (block * 512) + (n * 64);
  for (int i = 0; i < 64; i++)
    printf("%c", (char) (memory[62464 + start + i] & 0xFF));
  printf("\n");
}

void stats() {
  printf("Free: %d | Heap: %d | ", 62463 - Heap, Heap);
  printf("%d : %d : %d | %c\n", Current, Row, Column, (Mode ? 'I' : 'C'));
}

void block_display(int n) {
  for (int line = 0; line < 8; line++)
    row(n, line);
  sep();
  stats();
}
````

## Unsorted

````
void red_enter(int ch) {
  stack_push(ch);
  evaluate("red:insert-char");
}

void display_stack() {
  for (CELL i = 1; i <= sp; i++)
    (i == sp) ? printf("< %d >", data[i]) : printf("%d ", data[i]);
  printf("\n");
}

void save() {
  FILE *fp;
  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }
  memory[d_xt_for("red:Mode", Dictionary)] = 0;
  fwrite(&memory, sizeof(CELL), IMAGE_SIZE, fp);
  fclose(fp);
}

int main() {
  term_setup();
  ngaPrepare();
  ngaLoadImage("ngaImage");
  update_state();
  int ch;
  char c[] = "red:c_?";
  char i[] = "red:i_?";
  while (1) {
    update_state();
    term_clear();
    block_display(Current);
    display_stack();
    term_move_cursor(Column + 1, Row + 1);
    ch = getchar();
    if (Mode == 0) {
      c[6] = ch;
      CELL dt = d_lookup(Dictionary, c);
      if (dt != 0) execute(memory[d_xt(dt)]);
    } else if (Mode == 1) {
      i[6] = ch;
      CELL dt = d_lookup(Dictionary, i);
      (dt != 0) ? execute(memory[d_xt(dt)]) : red_enter(ch);
    }
    update_state();
    if (Mode == 2) {
      term_move_cursor(1, 15);
      term_cleanup();
      save();
      exit(0);
    }
  }
  return 0;
}
````
