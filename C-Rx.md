# C API for Rx

As with Nga, Rx is designed to be embedded and customized. This is a C language API for interacting with an Rx system. It includes an example *listener* which provides a minimal means of interacting with Rx, using the API and standard C libraries.

NOTE: this is *very* early. Expect a lot of changes to occur in the near future.

Compile with **-DINTERACTIVE** for the embedded listener.

## Notes

Things this needs to do:

* copy strings into the image
* copy strings out of the image
* push values to stack
* pop values from stack
* search the dictionary
* evaluate specific functions
* create new headers

Prefix for namespace reasons?

Is C-Rx an ok name for this?

My eventual goal for this is to provide command line, server side, and iOS interfaces to Rx and Nga.

## Headers

````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
````

## Nga

Include Nga.

````
#include "nga.c"
````

## Strings

Nga's cell based memory model means that we need to provide some means of copying ASCII data between C and Rx.

To copy data into the Rx memory use **crx\_string\_inject(str, at)**. The *str* argument is a pointer to a C string, *at* is the initial address in the image where the string should be stored.

````
void string_inject(char *str, int buffer) {
  int m = strlen(str);
  int i = 0;
  while (m > 0) {
    memory[buffer + i] = (CELL)str[i];
    memory[buffer + i + 1] = 0;
    m--; i++;
  }
}
````

Retrieving data is slightly more complex. C-Rx provides **crx\_string\_extract(at)** for reading a string into a dedicated buffer named **crx\_string\_data**.

````
char string_data[8192];

char *string_extract(int at)
{
  CELL starting = at;
  CELL i = 0;
  while(memory[starting] && i < 8192)
    string_data[i++] = (char)memory[starting++];
  string_data[i] = 0;
  return (char *)string_data;
}
````

## Dictionary

````
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
  char *d_name;
  while (memory[i] != 0 && i != 0) {
    d_name = string_extract(i + 3);
    if (strcmp(d_name, name) == 0) {
      dt = i;
      i = 0;
    } else {
      i = memory[i];
    }
  }
  return dt;
}
````

## Execution

````
void execute(int cell) {
  CELL opcode;

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
````

## ...

````
#ifdef INTERACTIVE
void dump_stack() {
  printf("Stack: ");
  for (CELL i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");
}

int main(int argc, char **argv) {
  printf("rx-2016.09 [C-Rx Listener]\n");
  ngaPrepare();
  ngaLoadImage("ngaImage");

  CELL Dictionary = memory[2];
  CELL Compiler = findDictionaryHeader(Dictionary, "Compiler");
  Compiler = memory[Compiler + 1];

  CELL Heap = memory[3];

  CELL interpret = findDictionaryHeader(Dictionary, "interpret");
  interpret = memory[interpret + 1];

  printf("%d MAX, %d Heap begins\n\n", IMAGE_SIZE, Heap);

  char input[1024];

  while(1) {
    if (memory[Compiler] == 0) {
      printf(" ok  ");
    }
    Dictionary = memory[2];
    scanf("%s", input);
    if (strcmp(input, "bye") == 0)
      exit(0);
    if (strcmp(input, "words") == 0) {
      CELL i = Dictionary;
      while (memory[i] != 0) {
        string_extract(i+3);
        printf("%s  ", string_data);
        i = memory[i];
      }
      printf("(%d entries)\n", countDictionaryEntries(Dictionary));
    }
    if (strcmp(input, ".s") == 0) {
      dump_stack();
    }
    string_inject(input, 16384);
    sp++;
    data[sp] = 16384;
    execute(interpret);
  }



  exit(0);
}
#endif
````
