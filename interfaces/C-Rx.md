# C API for Rx

As with Nga, Rx is designed to be embedded and customized. This is a C language API for interacting with an Rx system. It includes an example *listener* which provides a minimal means of interacting with Rx, using the API and standard C libraries.

NOTE: this is *very* early. Expect a lot of changes to occur in the near future.

Compile with **-DINTERACTIVE** for the embedded listener.

## Notes

Finished:

* push values to stack
* pop values from stack
* copy strings into the image
* copy strings out of the image
* search the dictionary
* dictionary field accessors
* count dictionary items
* evaluate specific functions

Todo:

Things this needs to do:

* create new headers

My eventual goal for this is to provide command line, server side, and iOS interfaces to Rx and Nga.

## Headers &amp; Nga

Just some standard, boring red tape.

````
/* c-rx.c, copyright (c) 2016 charles childers */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "nga.c"
````

## Stack

````
CELL stack_pop() {
  sp--;
  return data[sp + 1];
}

void stack_push(CELL value) {
  sp++;
  data[sp] = value;
}
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

The dictionary in Rx is a linked list, with each entry consisting of a few fields:

| offset | field | holds                                       |
| ------ | ----- | ------------------------------------------- |
| 0      | link  | link to the previous entry, 0 if last entry |
| 1      | xt    | link to start of the function               |
| 2      | class | link to the class handler function          |
| 3      | name  | zero terminated string                      |

C-Rx provides a few functions for addressing these fields:

````
#define D_OFFSET_LINK  0
#define D_OFFSET_XT    1
#define D_OFFSET_CLASS 2
#define D_OFFSET_NAME  3

int d_link(CELL dt) {
  return dt + D_OFFSET_LINK;
}

int d_xt(CELL dt) {
  return dt + D_OFFSET_XT;
}

int d_class(CELL dt) {
  return dt + D_OFFSET_CLASS;
}

int d_name(CELL dt) {
  return dt + D_OFFSET_NAME;
}
````

The next function allows counting the number of entries in the dictionary.

````
int d_count_entries(CELL Dictionary) {
  CELL count = 0;
  CELL i = Dictionary;
  while (memory[i] != 0) {
    count++;
    i = memory[i];
  }
  return count;
}
````

And finally, a function to lookup a header.

````
int d_lookup(CELL Dictionary, char *name) {
  CELL dt = 0;
  CELL i = Dictionary;
  char *dname;
  while (memory[i] != 0 && i != 0) {
    dname = string_extract(d_name(i));
    if (strcmp(dname, name) == 0) {
      dt = i;
      i = 0;
    } else {
      i = memory[i];
    }
  }
  return dt;
}
````

````
CELL d_xt_for(char *Name, CELL Dictionary) {
  return memory[d_xt(d_lookup(Dictionary, Name))];
}

CELL d_class_for(char *Name, CELL Dictionary) {
  return memory[d_class(d_lookup(Dictionary, Name))];
}
````

## Execution

This is a slightly tweaked version of the example bytecode processor from Nga. In a standalone implementation running just the image, control starts at the beginning and ends with the **END** instruction. But that's not what we want here. For an embedded application, this allows for executing a single function and returning to the high level code. This cheats a bit.

Execution stops when the instruction pointer (*ip*) reaches the end of memory. To find out when our initial function is done, we set the return pointer (*rp*) to a dummy depth of 1. When the top level **RETURN** instruction runs, this will reduce *rp* to zero, allowing us to know that control should be returned to the C code by jumping *ip* to the end of memory.

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

CELL Dictionary, Heap, Compiler;

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
````

The prompt should only show if the compiler is off.

````
void prompt() {
  if (memory[Compiler] == 0)
    printf(" ok  ");
}
````

````
void read_token(FILE *file, char *token_buffer) {
  if (file == NULL)
  {
    printf("Error: file pointer is null.");
    exit(1);
  }

  char ch = getc(file);
  int count = 0;

  while ((ch != '\n') && (ch != ' ') && (ch != EOF))
  {
    token_buffer[count++] = ch;
    ch = getc(file);
  }

  token_buffer[count] = '\0';
}


void include_file(char *fname) {
  char source[64000];
  FILE *fp;

  fp = fopen(fname, "r");
  if (fp == NULL)
    return;

  CELL interpret;
  interpret = d_xt_for("interpret", Dictionary);

  while (!feof(fp))
  {
    read_token(fp, source);
    Dictionary = memory[2];
    if (strlen(source) != 0) {
      string_inject(source, Heap - 1024);
      stack_push(Heap - 1024);
      execute(interpret);
    }
  }

  fclose(fp);
}
````

````
int main(int argc, char **argv) {
  CELL interpret;

  printf("rx-2016.09 [C-Rx Listener]\n");
  ngaPrepare();
  ngaLoadImage("ngaImage");

  Dictionary = memory[2];
  Heap = memory[3];
  Compiler = d_xt_for("Compiler", Dictionary);
  interpret = d_xt_for("interpret", Dictionary);

  printf("%d MAX, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE, Heap - 1024, Heap);

  char input[1024];

  include_file("startup.rx");

  while(1) {
    prompt();
    Dictionary = memory[2];
    scanf("%s", input);
    if (strcmp(input, "bye") == 0)
      exit(0);
    if (strcmp(input, "words") == 0) {
      CELL i = Dictionary;
      while (memory[i] != 0) {
        string_extract(d_name(i));
        printf("%s  ", string_data);
        i = memory[i];
      }
      printf("(%d entries)\n", d_count_entries(Dictionary));
    }
    if (strcmp(input, ".s") == 0) {
      dump_stack();
    }
    string_inject(input, Heap - 1024);
    stack_push(Heap - 1024);
    execute(interpret);
  }
  exit(0);
}
#endif
````
