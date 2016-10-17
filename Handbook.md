# Retro Forth Handbook

## Overview

Retro is a dialect of Forth. It differs from traditional Forth systems in many ways.

Syntax: Retro has a more structured syntax than tradtional Forth dialects. There are prefixes, which tell the language how to deal with words, quotations for stack and flow control, and some limits on word namings.

## Syntax

Code is delimited into tokens, which start and end with whitespace (with one exception).

### Prefixes

Tokens may have a single character prefix which tells Retro how to deal with them.

| prefix | used for                           |
| ------ | ---------------------------------- |
| &amp;  | pointer to a word                  |
| $      | ASCII character                    |
| '      | string (ending at the next ')      |
| #      | numbers                            |
| :      | start a new word                   |
| `      | directly inline a value            |
| (      | start a stack comment              |

### Quotations

Retro makes extensive use of quotations (anonymous code blocks).

| word  | usage             |
| ----- | ----------------- |
| &#91; | start a quotation |
| &#93; | end a quotation   |

### Naming

Any characters other than whitespace are valid in word names. However word names may not start with a prefix character.

Some conventions:

* Word names should be lowercase, with a single dash separating multiple words in a name

    length
    to-uppercase

* Use a prefix string to identify related words

    str:length
    str:to-uppercase
    chr:to-uppercase


* Variables should capitialize the first letter of each word and not include dashes separating elements

    Base
    CurrentColor

* Constants should be uppercase with dashes between elements in the word name

    BLOCK-BUFFER
    DECIMAL

* Words returning a flag should end in ?

    chr:uppercase?

* A dash at the start of a word name implies *not*:

    zero?
    -zero?
    if
    -if

## Stack

Being a Forth dialect, Retro is stack oriented. Values are pushed to the stack and removed by the words being run.

    #100 #200 #300 + -

Retro will:

* Push 100 to the stack
* Push 200 to the stack
* Push 300 to the stack
* **+** pops the top two items (300 and 200), adds them, then pushes the result to the stack
* **-** pops the top two values (now 500 and 100) from the stack and subtracts the top (500) from the second (100), pushing the result to the stack

Words that operate on the stack:

... fill this in ...

## Combinators

Combinators are words that operate on other words or quotations.

### Conditionals

Retro provides several combinators which conditionally execute other code.

**choose** takes a flag and two pointers. If the flag is **TRUE** it will execute the first quote. If **FALSE** it will execute the second.

    flag true-pointer false-pointer choose

**if** takes a flag and a pointer. If the flag is **TRUE** it will execute the quote. If **FALSE** it does nothing.

    flag true-pointer if

**-if** takes a flag and a pointer. If the flag is **FALSE** it will execute the quote. If **TRUE** it does nothing.

    flag false-pointer -if

**case** is a bit more complex. An example:

    :foo (n-N)
      dup #1 [ #-1 * ] case
          #2 [ #3 + ] case
          #6 [ #9 - ] case ;

You can use **case** to execute one of several blocks. If the value matches the key value **case** will drop the value and execute the code block before exiting the calling word.

So if *2* is passed to *foo* it first makes a copy **dup**, then compares the value to *1*. Since it doesn't match, it moves to the next *2*, which matches. **case** then executes the quote (*3 +*) and *foo* exits.

----

## Word Index

### Globals

### str:

The **str** namespace contains words that operate on strings.

### chr:

The **chr** namespace contains words that operate on characters.

### n:

The **n** namespace contains words that operate on numbers.

### err:

The **err** namespace contains words that deal with errors.

### compiler:

The **compiler** namespace contains words that help with implementing compiler macros.

### prefix:

The **prefix** namespace contains the words that implement the prefixes.
