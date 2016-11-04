#include <stdio.h>
#include <stdlib.h>
#include "bridge.c"
#define ED_BUFFER 327680
#define ED_BLOCKS 384
#include <termios.h>
#include <sys/ioctl.h>
struct termios new_termios, old_termios;
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
void term_clear() {
  printf("\033[2J\033[1;1H");
}
void term_move_cursor(int x, int y) {
  printf("\033[%d;%dH", y, x);
}
CELL Current;
CELL Column;
CELL Row;
CELL Mode;
void update_state() {
  update_rx();
  Current = memory[d_xt_for("ed:Current", Dictionary)];
  Column = memory[d_xt_for("ed:Col", Dictionary)];
  Row = memory[d_xt_for("ed:Row", Dictionary)];
  Mode = memory[d_xt_for("ed:Mode", Dictionary)];
}
void sep() {
  for (int i = 0; i < 8; i++)
    printf("--------");
  printf("\n");
}
void row(int block, int n) {
  int start = (block * 512) + (n * 64);
  for (int i = 0; i < 64; i++)
    printf("%c", (char) (memory[ED_BUFFER + start + i] & 0xFF));
  printf("\n");
}
void stats() {
  printf("Free: %d | Heap: %d | ", 326140 - Heap, Heap);
  printf("%d : %d : %d | %c\n", Current, Row, Column, (Mode ? 'I' : 'C'));
}
void block_display(int n) {
  for (int line = 0; line < 8; line++)
    row(n, line);
  sep();
  stats();
}
void red_enter(int ch) {
  stack_push(ch);
  evaluate("ed:insert-char");
}
void display_stack() {
  for (CELL i = 1; i <= sp; i++)
    (i == sp) ? printf("< %d >", data[i]) : printf("%d ", data[i]);
  printf("\n");
}
void save() {
  FILE *fp;
  memory[d_xt_for("ed:Mode", Dictionary)] = 0;
  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }
  fwrite(&memory, sizeof(CELL), IMAGE_SIZE, fp);
  fclose(fp);
}
void write_BUFFER() {
  FILE *fp;
  if ((fp = fopen("retro.blocks", "wb")) != NULL) {
    CELL slot;
    for(int i = ED_BUFFER; i < IMAGE_SIZE; i++) {
      slot = memory[i];
      fwrite(&slot, sizeof(CELL), 1, fp);
    }
    fclose(fp);
  }
}
void read_blocks() {
  FILE *fp;
  if ((fp = fopen("retro.blocks", "rb")) != NULL) {
    CELL slot;
    for (int i = ED_BUFFER; i < IMAGE_SIZE; i++) {
      fread(&slot, sizeof(CELL), 1, fp);
      memory[i] = slot;
    }
    fclose(fp);
  }
}
void initialize_rx() {
  ngaPrepare();
  ngaLoadImage("ngaImage");
  read_blocks();
  update_state();
}
int main() {
  initialize_rx();
  term_setup();
  int ch;
  char c[] = "ed:c_?";
  char i[] = "ed:i_?";
  while (1) {
    update_state();
    term_clear();
    block_display(Current);
    display_stack();
    term_move_cursor(Column + 1, Row + 1);
    ch = getchar();
    if (Mode == 0) {
      c[5] = ch;
      CELL dt = d_lookup(Dictionary, c);
      if (dt != 0) execute(memory[d_xt(dt)]);
    } else if (Mode == 1) {
      i[5] = ch;
      CELL dt = d_lookup(Dictionary, i);
      (dt != 0) ? execute(memory[d_xt(dt)]) : red_enter(ch);
    }
    update_state();
    if (Mode == 2) {
      term_move_cursor(1, 15);
      term_cleanup();
      save();
      write_BUFFER();
      exit(0);
    }
  }
  return 0;
}
