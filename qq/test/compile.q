\l ../qq.q

.qq.compile[enlist`foo]~"(`foo)"

\c 1 1
l:{x~get .qq.compile $[type[x]in 0 11 -11h;enlist x;x]};
m:{(first x;0#x;1#x;2#x;x 0 0N 2;x 0N 1 0N;x)};
l ()
l m 10000?0b
l m 10000?0x00
l m 10000?"c"$til 256
l m 10000?`5
l m 10000?0h
l m 10000?0i
l m 10000?0j
l m 5*-1+10000?2e
l m 5*-1+10000?2f
l m exp 100*-1+10000?2e
l m exp 100*-1+10000?2f
l m 10000?0p
l m 10000?00n

\\
