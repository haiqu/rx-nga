--------------------------------------

RETRO only supports decimal values out of the box. This extends it to become more flexible, handling (at a minimum) decimal, hexadecimal, octal, and binary.

**Base** stores the current numeric base.

````
#10 'Base var<n>
````

These words change **Base**.

````
:decimal #10 &Base store ;
:hexadecimal #16 &Base store ;
:octal #8 &Base store ;
:binary #2 &Base store ;
````

This next word will be used to replace the existing **str:to-number**:

````
{{
  'Sign var

  :to-digit (c-n)
    $0 -
    &Base fetch #16 eq? 0; drop
    dup #9 gt? [ #7 - ] if ;
---reveal---
  :str:to-number-patched (s-n)
    #1 &Sign store
    #0 swap
    [ dup $- eq?
      [ drop #-1 &Sign store ]
      [ [ &Base fetch * ] dip
        to-digit + ] choose
    ] str:for-each &Sign fetch * ;
}}
````

Now we can patch the code for **str:to-number** to point to our patched version. This replaces the first few cells with the following:

    lit
    pointer to str:to-number-patched
    jump

It assumes that the **str:to-number** is at least three cells long; if yours is shorter there will be problems.

````
#1 &str:to-number
&str:to-number-patched &str:to-number n:inc
#7 &str:to-number n:inc n:inc
store store store
````

Next up is a word to convert a number to a string.

````
{{
  '0123456789ABCDEF str:keep
  'DIGITS const
  :digit    (n-nn)  &Base fetch /mod ;
  :extract  (a-...)
    [ digit dup n:zero? ] until drop ;
---reveal---
  :n:to-string-patched (n-s)
     here buffer:set
     [ extract ]
     [ &DIGITS + fetch buffer:add ]
     for-each:result
     &DIGITS + fetch buffer:add
     buffer:start str:temp ;
}}
````

And as before, we patch the original **n:to-string** with the patched version.

````
#1 &n:to-string
&n:to-string-patched &n:to-string n:inc
#7 &n:to-string n:inc n:inc
store store store
````

And we're done. We can now use numbers in multiple bases within RETRO.

--------------------------------------
