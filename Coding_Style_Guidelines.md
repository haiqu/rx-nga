# Formatting

* Source should be in ASCII or UTF-8 format
* Use 2 space indents, no tabs
* Avoid trailing whitespace
* Use Unix-style line endings
* All named functions should have a stack comment
* If a function is more than one line, start the code on the line following the stack comment
* Short, one line definitions are preferred, but you can split functions into multiple lines when necessary

# Naming Conventions

Keep names short, but still readable and descriptive.

Standard functions should be lowercase, with dashes (-) separating words if the name is long enough.

Use a prefix word followed by a colon to identify related words.

E.g,

    str:compare
    str:length

Variables and data structure names should be Title case.

E.g.,

    Dictionary
    Heap
    Compiler

Names should never start with a prefix character. Look for words starting with **prefix:** to identify the prefix characters, or refer to the *Prefixes* section of the documentation for a current list.

E.g., don't do this:

    $foo
    &bar

Words returning a Boolean flag should generally end in a ?

The use of a leading dash indicates "not". E.g., **if** and **-if**. 

# Coding Guidelines

Keep definitions short

Factor heavily, but control visibility of internal factors using the scope functions

