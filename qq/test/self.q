\l ../qq.q

lines:read0`:../qq.q;
.qq.l @[lines;0;,;"1"]; // .qq1 - recompiled self
.qq1.l @[lines;0;,;"2"]; // .qq2 - again
(-3!'.qq1)~(-3!'.qq2)

.qq.profiling:1b; // .qq does the profiling
.qq.l @[lines;0;,;"p"]; // .qqp - instrumented code
.qqp.profiling:1b; // enable profiling here too to exercise that path
.qqp.l @[lines;0;,;"p1"]; // run instrumented code; output unused
\c 60 132
show`total xdesc
    update perself:self div calls, pertop:total div top from .qq.profile;

\\
