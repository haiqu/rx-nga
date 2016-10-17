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
:red:Current `0 ;
:red:Row `0 ;
:red:Col `0 ;
:red:Mode `0 ;
````

## Constraints

The cursor position (determined by **red:Row** and **red:Col**) needs to be within the block coordinates. Blocks are 8 rows of 64 characters. Additionally, the current block (**red:Current**) needs to be in the range of valid blocks so we can avoid memory corruption. This word is used to keep these values within the necessary boundaries. Any words that modify these bits of state should call this to keep things orderly.

````
:red:constrain
  &red:Row #0 #7 v:limit
  &red:Col #0 #63 v:limit
  &red:Current #0 red:#BLOCKS n:dec v:limit ;
````

## Commands

The editor has two modes: command and insertion. These words switch between them.

````
:red:command-mode #0 &red:Mode store ;
:red:insert-mode  #1 &red:Mode store ;
:red:quit-mode    #2 &red:Mode store ;
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

## Input

````
:red:index (-a)
  &red:Current fetch #512 *
  &red:Row fetch #64 * +
  &red:Col fetch + ;

:red:control
   #8 [ red:cursor-left ] case
  #10 [ #0 &red:Col store &red:Row v:inc ] case
  #13 [ #0 &red:Col store &red:Row v:inc ] case
 #127 [ red:cursor-left ] case
 drop ;

:red:insert-char
  dup chr:visible?
  [ red:index red:BLOCKS + store red:cursor-right ]
  [ red:control red:constrain ] choose ;
````

## Block Evaluation

The strategy here:

* Copy a token (ending with a space or end of block) to a buffer
* Interpret the buffer
* Repeat until the end of the block

````
{{
  :TIB #1471 ;
  :red:End `0 ;
  :red:Count `0 ;

  :getc
    red:BLOCKS
    &red:Current fetch #512 * +
    &red:End fetch +
    fetch
    &red:End v:inc ;

  :append   (c-)  &red:Count fetch TIB + store &red:Count v:inc ;
  :-empty? (s-sf) dup str:length n:positive? ;
  :-end?    (-f)  &red:End fetch #512 lt? ;
---reveal---
  :red:token
    #0 &red:Count store
    [ getc dup append #32 -eq? -end? and ] while
    #0 TIB &red:Count fetch + n:dec store TIB ;
  :red:evaluate-block
    #0 &red:End store
    [ red:token -empty? [ interpret ] [ drop ] choose -end? ] while ;
}}
````

## Key Handlers

### Command Mode

Command mode has a number of handlers since it's where most interactions take place.

| Key | Usage                  |
| --- | ---------------------- |
| n   | switch to next block   |
| p   | switch to prior block  |
| i   | move cursor up         |
| j   | move cursor left       |
| k   | move cusor down        |
| l   | move cursor right      |
| q   | exit the editor        |
| e   | evaluate the block     |
| \   | switch to insert mode  |

````
:red:c_n red:next-block ;
:red:c_p red:prior-block ;
:red:c_i red:cursor-up ;
:red:c_j red:cursor-left ;
:red:c_k red:cursor-down ;
:red:c_l red:cursor-right ;
:red:c_\ red:insert-mode ;
:red:c_q red:quit-mode ;
:red:c_e red:evaluate-block red:constrain ;
````

### Insertion Mode

This is intentionally kept to a minimal list as I don't want to restrict what can be input. Just one command, **\**, which returns to command mode.

| Key | Usage                  |
| --- | ---------------------- |
| \   | switch to insert mode  |

````
:red:i_\ red:command-mode ;
````

## Initialize Block Buffer

Fills all the block space with ASCII 32 (spaces)

````
red:BLOCKS red:#BLOCKS #512 * [ #32 swap store-next ] times drop
````
