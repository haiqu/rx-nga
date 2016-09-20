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


# Coding Guidelines

Keep definitions short

Factor heavily, but control visibility of internal factors using the scope functions

