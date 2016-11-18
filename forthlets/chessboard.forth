# CHESS

````
{{ 
  :str:, (s-)
   [ , ] str:for-each ; 
 
  'Blank d:create
  'rnbqkbnrpppppppp str:,
  '................ str:,
  '................ str:,
  'PPPPPPPPRNBQKBNR str:, #0 ,

  'Board d:create
  #64 allot 
 
  :--- (-) 
    sp sp
    '+-----------------+ puts nl ;
  :cols (-)
    sp sp sp sp
  '0_1_2_3_4_5_6_7 puts nl ;
  :row (a-a)
    putn $| putc sp
    #8 [ fetch-next putc sp ] times
    $| putc nl ;
  :get (rc-a) swap #8 * &Board + + ;
---reveal---
  :chess:display (-)
    nl cols ---
    &Board #0 row
           #1 row
           #2 row
           #3 row
           #4 row
           #5 row
           #6 row
           #7 row drop
    --- cols nl ;
  :chess:new (-)
    &Blank &Board #64 copy ;
  :chess:move (rcrc-)
    get [ get ] dip swap
    dup fetch swap $. swap store
    swap store ;
}}

  chess:new
  #0 #0 #2 #1 chess:move chess:display
````

