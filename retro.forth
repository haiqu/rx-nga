:EOM       #524287 ;
:STRINGS   EOM #12 #128 * - ;
:prefix:( drop ;
  &class:macro
  &Dictionary fetch d:class store
:d:last (-d) &Dictionary fetch ;
:d:last<xt> (-a) d:last d:xt fetch ;
:d:last<class> (-a) d:last d:class fetch ;
:d:last<name> (-s) d:last d:name ;
:reclass    (a-) d:last d:class store ;
:immediate  (-)  &class:macro reclass ;
:data       (-)  &class:data reclass ;
:here  (-a) &Heap fetch ;
:compile:lit  (a-) #1 , , ;
:compile:jump (a-) compile:lit #7 , ;
:compile:call (a-) compile:lit #8 , ;
:compile:ret  (-)  #10 , ;
:prefix:` (s-) &Compiler fetch [ str:to-number , ] [ drop ] choose ; immediate
:d:create (s-)
  (s-) &class:data #0 d:add-header
  here d:last d:xt store ;
:var    (s-)  d:create #0 , ;
:var<n> (ns-) d:create , ;
:const  (ns-) d:create d:last d:xt store ;
:TRUE  (-n) #-1 ;
:FALSE (-n)  #0 ;
:n:zero?     (n-f)  #0 eq? ;
:n:-zero?    (n-f)  #0 -eq? ;
:n:negative?  (n-f)  #0 lt? ;
:n:positive?  (n-f)  #0 gt? ;
:dip  (nq-n)  swap push call pop ;
:sip  (nq-n)  push dup pop swap &call dip ;
:bi  (xqq-)  &sip dip call ;
:bi*  (xyqq-) &dip dip call ;
:bi@  (xyq-)  dup bi* ;
:tri  (xqqq-)  [ &sip dip sip ] dip call ;
:tri*  (xyzqqq-)  [ [ swap &dip dip ] dip dip ] dip call ;
:tri@ dup dup tri* ;
:while  (q-)  [ repeat dup dip swap 0; drop again ] call drop ;
:until  (q-)  [ repeat dup dip swap #-1 xor 0; drop again ] call drop ;
:times  (q-)  swap [ repeat 0; #1 - push &call sip pop again ] call drop ;
:compiling?  (-f)  &Compiler fetch ;
:depth (-n) #-1 fetch ;
:reset (...-) depth [ drop ] times ;
:tuck      (xy-yxy)   dup push swap pop ;
:over      (xy-xyx)   push dup pop swap ;
:dup-pair  (xy-xyxy)  over over ;
:nip       (xy-y)     swap drop ;
:drop-pair (nn-)      drop drop ;
:?dup      (n-nn||n-n) dup 0; ;
:rot       (abc-bca)   [ swap ] dip swap ;
:tors (-n)  pop pop dup push swap push ;
:/         (nq-d)  /mod swap drop ;
:mod       (nq-r)  /mod drop ;
:*/        (nnn-n) push * pop / ;
:not       (n-n)   #-1 xor ;
:n:pow     (bp-n)  #1 swap [ over * ] times nip ;
:n:negate  (n-n)   #-1 * ;
:n:square  (n-n)   dup * ;
:n:sqrt    (n-n) #1 [ repeat dup-pair / over - #2 / 0; + again ] call nip ;
:n:min     (nn-n)  dup-pair lt? [ drop ] [ nip ] choose ;
:n:max     (nn-n)  dup-pair gt? [ drop ] [ nip ] choose ;
:n:abs     (n-n)   dup n:negate n:max ;
:n:limit   (nlu-n) swap push n:min pop n:max ;
:n:inc     (n-n)   #1 + ;
:n:dec     (n-n)   #1 - ;
:n:between? (nul-) rot [ rot rot n:limit ] sip eq? ;
:v:inc-by  (na-)   [ fetch + ] sip store ;
:v:dec-by  (na-)   [ fetch swap - ] sip store ;
:v:inc     (n-n)   #1 swap v:inc-by ;
:v:dec     (n-n)   #1 swap v:dec-by ;
:v:limit   (alu-)  push push dup fetch pop pop n:limit swap store ;
:allot     (n-)    &Heap v:inc-by ;
:v:update-using (aq-) swap [ fetch swap call ] sip store ;
:ScopeList `0 `0 ;
:{{ d:last dup &ScopeList store-next store ;
:---reveal--- d:last &ScopeList n:inc store ;
:}} &ScopeList fetch-next swap fetch eq? [ &ScopeList fetch &Dictionary store ] [ &ScopeList fetch [ &Dictionary repeat fetch dup fetch &ScopeList n:inc fetch -eq? 0; drop again ] call store ] choose ;
{{
  :Buffer `0 ; data
  :Ptr    `0 ; data
  :terminate (-) #0 &Ptr fetch store ;
---reveal---
  :buffer:start  (-a) &Buffer fetch ;
  :buffer:end    (-a) &Ptr fetch ;
  :buffer:add    (c-) buffer:end store &Ptr v:inc terminate ;
  :buffer:get    (-c) &Ptr v:dec buffer:end fetch terminate ;
  :buffer:empty  (-)  buffer:start &Ptr store terminate ;
  :buffer:size   (-n) buffer:end buffer:start - ;
  :buffer:set    (a-) &Buffer store buffer:empty ;
}}
:later pop pop swap push push ;
:copy   (aan-) [ &fetch-next dip store-next ] times drop drop ;
{{
  :MAX-LENGTH #128 ;
  :str:Current `0 ; data
  :str:pointer (-p)  &str:Current fetch MAX-LENGTH * STRINGS + ;
  :str:next    (-) &str:Current v:inc &str:Current fetch #12 eq? [ #0 &str:Current store ] if ;
---reveal---
  :str:temp (s-s) dup str:length n:inc str:pointer swap copy str:pointer str:next ;
  :str:empty (-s) str:pointer str:next ;
}}
:str:skip (-) pop [ fetch-next #0 -eq? ] while n:dec push ;
:str:keep (s-s) compiling? [ &str:skip class:word ] if here [ s, ] dip class:data ;
:prefix:' compiling? [ str:keep ] [ str:temp ] choose ; immediate
:str:chop (s-s) str:temp dup str:length over + n:dec #0 swap store ;
:str:reverse (s-s)
  dup str:temp buffer:set &str:length [ dup str:length + n:dec ] bi swap
  [ dup fetch buffer:add n:dec ] times drop buffer:start str:temp ;
:str:trim-left (s-s) str:temp [ fetch-next [ #32 eq? ] [ #0 -eq? ] bi and ] while n:dec ;
:str:trim-right (s-s) str:temp str:reverse str:trim-left str:reverse ;
:str:trim (s-s) str:trim-right str:trim-left ;
:str:prepend (ss-s)
  str:temp [ dup str:length + [ dup str:length n:inc ] dip swap copy ] sip ;
:str:append (ss-s) swap str:prepend ;
{{
  :Needle `0 ; data
---reveal---
  :str:has-char?  (sc-f)
   &Needle store
   repeat
     fetch-next
     dup #0 eq? [ drop drop #0 #0 ] [ #-1 ] choose 0; drop
     &Needle fetch eq? [ #-1 #0 ] [ #-1 ] choose 0; drop
  again ;
}}
{{
  :<str:hash> repeat push #33 * pop fetch-next 0; swap push + pop again ;
---reveal---
  :str:hash  (s-n)  #5381 swap <str:hash> drop ;
}}
:chr:SPACE        (-c)  #32 ;
:chr:ESC          (-c)  #27 ;
:chr:TAB          (-c)  #9 ;
:chr:CR           (-c)  #13 ;
:chr:LF           (-c)  #10 ;
:chr:letter?      (c-f) $A $z n:between? ;
:chr:lowercase?   (c-f) $a $z n:between? ;
:chr:uppercase?   (c-f) $A $Z n:between? ;
:chr:digit?       (c-f) $0 $9 n:between? ;
:chr:whitespace?  (c-f) [ chr:SPACE eq? ] [ #9 eq? ] [ [ #10 eq? ] [ #13 eq? ] bi or ] tri or or ;
:chr:to-upper     (c-c) chr:SPACE - ;
:chr:to-lower     (c-c) chr:SPACE + ;
:chr:toggle-case  (c-c) dup chr:lowercase? [ chr:to-upper ] [ chr:to-lower ] choose ;
:chr:to-string    (c-s) '. str:temp [ store ] sip ;
:chr:visible?     (c-f) #31 #126 n:between? ;
{{
  :Value `0 ;
---reveal---
  :n:to-string  (n-s)
    here buffer:set dup &Value store n:abs
    [ #10 /mod swap $0 + buffer:add dup n:-zero? ] while drop
    &Value fetch n:negative? [ $- buffer:add ] if
    buffer:start str:reverse str:temp ;
}}
:cons (nn-p) here [ swap , , ] dip ;
:curry (vp-p) here [ swap compile:lit compile:call compile:ret ] dip ;
:case
  [ over eq? ] dip swap
  [ nip call #-1 ] [ drop #0 ] choose 0; pop drop drop ;
:str:for-each (sq-)
  [ repeat
      over fetch 0; drop
      dup-pair
      [ [ [ fetch ] dip call ] dip ] dip
      [ n:inc ] dip
    again
  ] call drop-pair ;
:does (q-)
  d:last<xt> swap curry d:last d:xt store &class:word reclass ;
{{
  :SystemState `0 `0 `0 ;
---reveal---
  :mark
    &Heap  fetch &SystemState #0 + store
    d:last &SystemState #1 + store ;
  :sweep
    &SystemState #0 + fetch &Heap store
    &SystemState #1 + fetch &Dictionary store ;
}}
{{
  'Values var #8 allot
  :from str:length dup [ [ &Values + store ] sip n:dec ] times drop ;
  :to dup str:length [ fetch-next $a -  n:inc &Values + fetch swap ] times drop ;
---reveal---
  :reorder (...ss-?) [ from ] dip to ;
}}
:putc (c-) `1000 ;
:nl   (-)  chr:LF putc ;
:puts (s-) [ putc ] str:for-each ;
:putn (n-) n:to-string puts chr:SPACE putc ;
