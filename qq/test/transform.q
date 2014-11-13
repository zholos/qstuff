\l ../qq.q

567=.qq.e["{a..b..c:5 6 7;c+10*b+10*a}"][]

104h=type .qq.e["{a:5;{a+1}}"][]
6=.qq.e["{a:5;{a+1}[]}"][]
11=.qq.e["{a:5;{b:6;{a+b}[]}[]}"][]
-8=.qq.e["{[a;b;c;d;e;f;g;h;i]a-i}"][1;2;3;4;5;6;7;8;9]

88=.qq.e["{a:3;{$[x>0;x+a+.z.s x-1;a]}10}"][]
88=.qq.e["{a:3;{[b;c;d;e;x;w;v;u]$[x>0;x+a+.z.s[b;c;d;e;x-1;w;v;u];a]",
               "}[1;1;1;1;10;1;1;1]}"][]

(1b;36;(::;(31;`));25;(::;(18;`)))~.qq.e[
    "{ff:{aa:5;bb:(::;(6;`));a:b:c:d:e:f:g:h:i:j:k:l:m:n:o:p:q:r:s:t:u:v:w:1;",
         "uu:7;vv:(::;(8;`));aa+:bb[1;0]+:uu+:vv[1;0]+:10;(.z.s;aa;bb;uu;vv)};
      @[ff[];0;ff~]}"][]

t:([]sym:`aaa`aaa`aaa`bbb`bbb`ccc`ccc;
     side:1 2 2 1 1 2 1;
     p:100 101 102 5 5.1 21 20;
     q:100 100 200 1000 3000 200 300);
(([grp:`aaa`bbb`ccc]p:101.25 5.075 20.4;q:400 4000 500);
 ([grp:1 2]p:8.25 69.4;q:4400 500))~{show x;x}each
    .qq.e["{[grp] select q wavg p, sum q by .grp. from t}"]each`sym`side
70000f~{show x;x}
    .qq.e["{[expr] exec 10000 xbar .expr. from t}"](sum;(*;`p;`q))

\\
