# C API for Rx

Compile with **-DINTERACTIVE** for an embedded listener.

````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "nga.c"

char request[8192];

void injectString(char *s, int buffer) {
  int m = strlen(s);
  int i = 0;
  while (m > 0) {
    memory[buffer + i] = (CELL)s[i];
    memory[buffer + i + 1] = 0;
    m--; i++;
  }
}

void nguraGetString(int starting)
{
  CELL i = 0;
  while(memory[starting] && i < 8192)
    request[i++] = (char)memory[starting++];
  request[i] = 0;
}


int countDictionaryEntries(CELL Dictionary) {
  CELL count = 0;
  CELL i = Dictionary;
  while (memory[i] != 0) {
    count++;
    i = memory[i];
  }
  return count;
}

int findDictionaryHeader(CELL Dictionary, char *name) {
  CELL dt = 0;
  CELL i = Dictionary;
  while (memory[i] != 0 && i != 0) {
    nguraGetString(i + 3);
    if (strcmp(request, name) == 0) {
      dt = i;
      i = 0;
    } else {
      i = memory[i];
    }
  }
  return dt;
}

void execute(int cell) {
  CELL opcode, i;

  rp = 1;

  ip = cell;
  while (ip < IMAGE_SIZE) {
    opcode = memory[ip];
    if (ngaValidatePackedOpcodes(opcode) != 0) {
      ngaProcessPackedOpcodes(opcode);
    } else if (opcode >= 0 && opcode < 27) {
      ngaProcessOpcode(opcode);
    } else {
      printf("Invalid instruction!\n");
      printf("At %d, opcode %d\n", ip, opcode);
      exit(1);
    }
    ip++;
    if (rp == 0)
      ip = IMAGE_SIZE;
  }
}

void dump_stack() {
  printf("Stack: ");
  for (CELL i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");
}

#ifdef INTERACTIVE
int main(int argc, char **argv) {
  ngaPrepare();
  ngaLoadImage("ngaImage");

  CELL Dictionary = memory[2];
  CELL Heap = memory[3];

  CELL i = Dictionary;

  while (memory[i] != 0) {
    nguraGetString(i+3);
    printf("Entry at %d\nName: %s\nXT: %d\nClass: %d\n\n", i, request, memory[i+1], memory[i+2]);
    i = memory[i];
  }

  printf("%d entries\n", countDictionaryEntries(Dictionary));

  CELL lookup = findDictionaryHeader(Dictionary, "interpret");
  lookup = memory[lookup + 1];
  printf("interpret @ %d\n", lookup);

  injectString("#100", 16384);
  sp++;
  data[sp] = 16384;

  dump_stack();

  execute(lookup);

  dump_stack();

  exit(0);
}
#endif
````
