# HTML Generation

RETRO 11 has a couple of libraries for creating CGI applications. I'd like to eventually support this in RETRO 12. The code here is one small part of that: code based generation of pages or portions of pages.

    [ [ 'Example_page title:
        'Example.css stylesheet:
      ] head
      [ [ 'Header! puts ] h1
        [ 'this_is_a_test puts [ '... puts ] strong ] p
        hr
        [ 'this_is_another_test puts [ '... puts ] em ] p
      ] body
    ] html

````
{{
  :open $< putc puts $> putc ;
  :close $< putc $/ putc puts $> putc ;
  :single  $< putc puts $/ putc $> putc ;
---reveal---
  :tag
    dup str:keep d:create ,
    [ fetch [ open call ] sip close ] does ;
  :tags
    depth [ call ] dip depth swap -
    [ tag ] times ;
  :single
    dup str:keep d:create ,
    [ fetch single ] does ;
  :singles
    depth [ call ] dip depth swap -
    [ single ] times ;
}}
````

## Tags

````
[ 'html 'head 'body ] tags
[ 'p 'div ] tags
[ 'strong 'em ] tags
[ 'br 'hr ] singles
````

## Test

````
[ [ [ 'hello puts ] p ] body ] html
````
