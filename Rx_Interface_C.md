````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "nga.c"

char request[8192];

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

  exit(0);
}
````
