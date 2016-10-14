# Retro Block Editor

This is one part of the Retro Block Editor. See *Editor.md* for the other portion.

The implementation is split into two parts: an *interface layer*, written in C, and the editor logic, which is written in Retro. The code here contains the editor logic including key handling.

This has been influenced by Sam Falvo II's VIBE. Key handlers are words in the dictionary. The interface layer will lookup names and call the words to handle each keystroke. Naming conventions for the key handlers are as follows:

| name    | used for             |
| ------- | -------------------- |
| red:c_? | keys in command mode |
| red:i_? | keys in insert mode  |

Replace the *?* with the ASCII symbol for the key you are handling.

## Configuration

Two constants: the start of the block buffer and the number of blocks.

````
:red:BLOCKS #62464 ;
:red:#BLOCKS  #120 ;
````

## Variables

There are a few global variables. These will hold the few pieces of state that we need.

````
:red:Current `0 ; data
:red:Row `0 ; data
:red:Col `0 ; data
:red:Mode `0 ; data
````

## Constraints

The cursor position (determined by **red:Row** and **red:Col**) needs to be within the block coordinates. Blocks are 8 rows of 64 characters. Additionally, the current block (**red:Current**) needs to be in the range of valid blocks so we can avoid memory corruption. This word is used to keep these values within the necessary boundaries. Any words that modify these bits of state should call this to keep things orderly.

````
:red:constrain
  &red:Row #0 #7 v:limit
  &red:Col #0 #63 v:limit
  &red:Current #0 #119 v:limit ;
````

## Commands

The editor has two modes: command and insertion. These words switch between them.

````
:red:command-mode #0 &red:Mode store ;
:red:insert-mode  #1 &red:Mode store ;
````

**red:Current** contains the current block. These commands allow switching between blocks.

````
:red:next-block   &red:Current v:inc red:constrain ;
:red:prior-block  &red:Current v:dec red:constrain ;
````

The cursor (insertion point) is determined by the **red:Row** and **red:Col** variables. The next group of commands move the cursor.

````
:red:cursor-up    &red:Row v:dec red:constrain ;
:red:cursor-down  &red:Row v:inc red:constrain ;
:red:cursor-left  &red:Col v:dec red:constrain ;
:red:cursor-right &red:Col v:inc red:constrain ;
````

## Unsorted

````
:red:index
  &red:Current fetch #512 *
  &red:Row fetch #64 * +
  &red:Col fetch + ;



:red:insert-controls
   #8 [ red:cursor-left ] case
 #127 [ red:cursor-left ] case
 drop ;
:red:insert-char
  dup chr:visible?
  [ red:index red:BLOCKS + store red:cursor-right ]
  [ red:insert-controls ] choose ;
````

````
:red:c_n red:next-block ;
:red:c_p red:prior-block ;
:red:c_i red:cursor-up ;
:red:c_j red:cursor-left ;
:red:c_k red:cursor-down ;
:red:c_l red:cursor-right ;
:red:c_/ red:insert-mode ;
:red:i_/ red:command-mode ;
````

````
red:BLOCKS #120 #512 * [ #32 swap store-next ] times drop
````
