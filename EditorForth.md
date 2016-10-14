:red:BlockBuffer #62464 ;
:red:Current `0 ; data
:red:Row `0 ; data
:red:Col `0 ; data
:red:Mode `0 ; data

:red:index
  &red:Current fetch #512 *
  &red:Row fetch #64 * +
  &red:Col fetch + ;

:red:constrain &red:Row #0 #7 v:limit &red:Col #0 #63 v:limit &red:Current #0 #119 v:limit ;

:red:next-block   &red:Current v:inc red:constrain ;
:red:prior-block  &red:Current v:dec red:constrain ;
:red:cursor-up    &red:Row v:dec red:constrain ;
:red:cursor-down  &red:Row v:inc red:constrain ;
:red:cursor-left  &red:Col v:dec red:constrain ;
:red:cursor-right &red:Col v:inc red:constrain ;
:red:command-mode #0 &red:Mode store ;
:red:insert-mode  #1 &red:Mode store ;
:red:insert-controls
   #8 [ red:cursor-left ] case
 #127 [ red:cursor-left ] case
 drop ;
:red:insert-char
  dup chr:visible?
  [ red:index red:BlockBuffer + store red:cursor-right ]
  [ red:insert-controls ] choose ;

:red:c_n red:next-block ;
:red:c_p red:prior-block ;
:red:c_i red:cursor-up ;
:red:c_j red:cursor-left ;
:red:c_k red:cursor-down ;
:red:c_l red:cursor-right ;
:red:c_/ red:insert-mode ;
:red:i_/ red:command-mode ;

red:BlockBuffer #120 #512 * [ #32 swap store-next ] times drop
