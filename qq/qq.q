\d .qq

preprocess:{
    // remove multiline comments
    x@:where not{x|prev x}"b"$0{-1|1&x+y-x<0}\0^("/\\"!1 -1)"C"$x;

    // combine with continuation lines
    x@:where not x[;0]="/";
    x:"\n"sv'(0,where not x[;0]in" \t")_x;

    x};

// Like builtin parse[], but function is ("{";params;tree) instead of literal.
parser:{
    // Can't use builtin parse[] because we want to work around 'locals.
    // Parse just enough to determine where function source starts and ends,
    // use parse[] for actual expressions.

    // system command
    if["\\"=x 0;
        :(system;1_x)];
    if[x like"[a-zA-Z])*";
        :(get;x)];

    // split into fragments with interesting characters
    x:enlist[""],where[{x|not prev not x}x in "\"/{}[]\n"]_x;

    // combine entire strings using q parser to handle escapes
    s:"\""={x[;0]}""{$["\""<>x 0;y;@[{get x;1b};x;0b];y;x,y]}\x;
    x:raze each where[not s&prev s]_x;

    // remove comments
    x@:where"b"$1h^\?[(x[;0]="/")&prev[last'[x]]in" \t\n";0h;0N 1h"\n"=x[;0]];

    // replace "\n" (parse[] doesn't handle it)
    x[where x[;0]="\n";0]:" ";

    // can't end with string
    if["\""=last[x]0;get last x];

    // combine function preamble
    f:"b"$0h^\?[all each x in\:" \t";0Nh;x[;0]="{"];
    x:raze each where[(x[;0]="{")|not f&prev f]_x;
    x:raze each where[not(x[;0]="[")&prev x[;0]="{"]_x;
    f:"b"$0h^\?[(x[;0]="{")&last'[x]="[";1h;?["]"=prev x[;0];0h;0Nh]];
    x:raze each where[(x[;0]="{")|not f&prev f]_x;

    // (text; params; replacements; stack)
    x:("";::;()!();::) {
        $["{"=y 0;
            ("";$[0~p:parse"0",1_y;::;enlist{$[x~(::);`;x]}'[1_p]];()!();x);
          "}"=y 0;
            @[;0;,;"(",string[f],")"]
            .[;2,f:`$".qq.func.",string count x[3;2];:;
                ("{";x 1;replaceNames[x 2] parse x 0)]
            x 3;
            @[x;0;,;y]]
        }/x;
    if[not(::)~x 3;'1#"{"];
    replaceNames[x 2] parse x 0
    };


// Parse tree traversal is tricky so it is handled by this single function.
// It visits every node (call, name, or literal).
// v[state;x] called when entering, returns (state; new x; recurse)
// d[state;x] called when departing, returns (state; new x)
// NOTE: Can be reimplemented iteratively to avoid 'stack.
visit:{[v;d;state;x]
    r:v[state;x];state:r 0;x:r 1;recurse:r 2;
    if[recurse;
        if[(1<count x)&type[x]in 0 11h;
            // visit in evaluation order, skipping elided arguments
            i:where not count each 0#\:'x;
            if[not any[x[0]~/:(";";`while;`do;`if)]|(($)~x 0)&2<count x;
                i:reverse i];
            r:(state;::){x[y 0;z]}[.z.s[v;d]]\x i;
            x:-1_@[x,(::);i;:;r[;1]];
            state:first last r];
        r:d[state;x];state:r 0;x:r 1];
    (state;x)
    };

modifyNodes:{[f;x]
    d:{[f;state;x](::;f x)}[f];
    last visit[(;;1b);d;::;x]
    };

replaceNames:{[d;x]
    f:{[d;x]$[-11h<>type x;x;x in key d;d x;x]}[d];
    modifyNodes[f;x]
    };

// Per-function state; global scope isn't visited (except function nodes).
visitFuncs:{[fv;fd;fstate;x]
    v:{[fv;fstate;state;x]
        if[(1<count x)&(0h=type x)&"{"~first x;
            state:(fstate;state)];
        if[count state;
            r:fv[state 0;x];state[0]:r 0;x:r 1];
        (state;x;1b)
        }[fv;fstate];
    d:{[fd;fstate;state;x]
        if[count state;
            r:fd[state 0;x];state[0]:r 0;x:r 1];
        if[(1<count x)&(0h=type x)&"{"~first x;
            state@:1];
        (state;x)
        }[fd;fstate];
    last visit[v;d;();x]
    };


// a..b..c:f[] -> (a:a 0;b:a 1;c:last 000b!a:f[])
multiAssign:{
    f:{
        if[$[(3=count x)&(:)~first x;-11h=type x 1;0b];
            if[x[1]like"*..*";
                v:(`$i[0]#v),`$2_'(i:where(v=".")&"."=next v)_v:string x 1;
                x:(enlist),
                    {(:;x;(y;z))}'[v;v 0;til count v:-1_v],
                    enlist(:;last v;(last;(!;count[v]#0b;(:;v 0;x 2))))]];
        x};
    modifyNodes[f;x]
    };

// select .foo.+1 by .bar. from t where .baz.
parametricQueries:{
    f:{
        p:{
            // NOTE: only unary functions touch elision :: here
            $[(1<count x)&type[x]in 0 11h;
                $[count n:(r:.z.s'[x])[;0]except`;
                    ($[any(+;-;*;%;&;|)~\:x 0;first;last]n;(enlist),r[;1]);
                    (`;enlist x)];
              -11h=type x;
                $[x like".*?.";
                    2#`$-1_1_string x;
                    (`;enlist x)];
                (`;x)]
            };
        if[(5=count x)&any(?;!)~\:first x;
            // Only process q-sql queries. They are distinguished from calls to
            // ?[;;;] by arguments that are single literals. Only replace with
            // expressions if any parameters are expanded.
            $[$[99h=type x 4;any`<>(r:p'[value x 4])[;0];0b]; // select
                x[4]:(!;enlist r[;0]^key x 4;(enlist),r[;1]);
              $[(1=count x 4)&type[x 4]in 0 11h;`<>(r:p x[4;0])0;0b]; // exec
                x[4]:r 1;
                ];
            if[$[99h=type x 3;any`<>(r:p'[value x 3])[;0];0b];
                x[3]:(!;enlist r[;0]^key x 3;(enlist),r[;1])];
            if[$[(1=count x 2)&type[x 2]in 0 11h;any`<>(r:p'[x[2;0]])[;0];0b];
                x[2]:(enlist),r[;1]];
            ];
        x};
    modifyNodes[f;x]
    };

// {z} -> {[x;y;z]z}
// {y:1} -> {[x;y]y:1} (q does this)
// After multiAssign in case that introduces new names.
autoParams:{
    fd:{[reads;x]
        if[-11h=type x;
            reads,:x];
        if[(1<count x)&(0h=type x)&"{"~first x;
            if[(::)~x 1;
                x[1]:enlist(1^1+last where d in reads)#d:`x`y`z]];
        (reads;x)
        };
    visitFuncs[(;);fd;();x]
    };

// Human-readable function identifiers for debugging.
// foo:{bar:{}}[{}]; (bar is named, foo is result of unnamed call)
functionNames:{
    // (name; seq; stack)
    v:{[state;x]
        if[(1<count x)&(0h=type x)&"{"~first x;
            if[3=count x; // anonymous function since no name assigned yet
                x,:enlist enlist ` sv(`$string 2#state)except`];
            state:(first x 3;0;state);
            ];
        if[$[(3=count x)&((:)~first x);-11h=type x 1;0b];
            // function, with possibly some bound arguments, assigned to name
            x[2]:{[name;bound;x]
                $[(1<count x)&(0h=type x)&"{"~first x;
                    if[(3=count x)&bound<count first x 1; // autoParams required
                        x,:enlist enlist name];
                  (1<count x)&0h=type x;
                    x[0]:.z.s[name;bound+count[x]-1;x 0];
                    ];
                x}[` sv(state 0;x 1)except`;0;x 2];
            ];
        (state;x;1b)
        };
    d:{[state;x]
        if[(1<count x)&(0h=type x)&"{"~first x;
            state@:2;
            state[1]+:1];
        (state;x)
        };
    last visit[v;d;(`;0);x]
    };

captureLocals:{
    // (locals; reads; stack)
    v:{[state;x]
        if[count state;
            $[$[(3=count x)&((:)~first x);-11h=type x 1;0b];
                state[0],:x 1; // simple assignment makes a local
              -11h=type x;
                state[1],:x;
                ]];
        if[(1<count x)&(0h=type x)&"{"~first x;
            state:(first x 1;();state)]; // params are considered locals too
        (state;x;1b)
        };
    d:{[state;x]
        if[(1<count x)&(0h=type x)&"{"~first x;
            locals:state 0;reads:state 1;state@:2;
            scope:raze last\[state][;0];
            if[count capture:(distinct[reads] except `.z.s,locals) inter scope;
                x[1]:enlist capture,first x 1;
                if[`.z.s in reads;
                    x[2]:(";";(:;`.z.s;`.z.s,capture);x 2)];
                x:enlist[x],capture;
                state[1],:capture];
            ];
        (state;x)
        };
    last visit[v;d;();x]
    };

// {[a;b;...]} -> (')[{[.qq.params]a:.qq.params 0;b:.qq.params 1;...};(;;...)]
// If .z.s is used, convert it in the preamble: .z.s:(')[.z.s;(;;...)]
moreParams:{
    fd:{[zs;x]
        if[(1<count x)&(0h=type x)&"{"~first x;
            if[8<count p:first x 1;
                l:parse["(;)"]0,count[p]#1;
                x[2]:";",(zs#enlist(:;`.z.s;(';`.z.s;l))),
                         {(:;x;(`.qq.params;y))}'[p;til count p],enlist x 2;
                x[1]:enlist 1#`.qq.params;
                x:(';x;l);
                ];
            ];
        if[x~`.z.s;
            zs:1b];
        (zs;x)
        };
    visitFuncs[(;);fd;0b;x]
    };

// Use a list to hold extra locals. .z.s behaves just like a local, but it's not
// counted towards the limit, so use it to hold the list. The first element is
// the actual .z.s (this also prevents the list from becoming a vector).
moreLocals:{
    fd:{[locals;x]
        if[$[(3=count x)&((:)~first x);-11h=type x 1;0b];
            locals[x 1]+:1]; // simple assignment makes a local
        if[(1<count x)&(0h=type x)&"{"~first x;
            // spill least referenced locals above limit
            spill:-23_idesc[locals]except`.z.s,first x 1;
            if[count spill;
                zslist:`.z.s,spill;
                v:{[zslist;state;x]
                    if[(1<count x)&(0h=type x)&"{"~first x;
                        :(::;x;0b)];
                    // name new .z.s as .qq.z.s temporarily
                    $[$[(1<count x)&type[x]in 0 11h;-11h=type x 0;0b];
                        // a[i]:` -> .z.s[0;i]:`, not .z.s[0][i]:`
                        if[x[0]in zslist;
                            x:`.qq.z.s,(zslist?x 0),1_x];
                      -11h=type x;
                        if[x in zslist;
                            x:`.qq.z.s,zslist?x];
                        ];
                    (::;x;1b)
                    }[zslist];
                d:{[state;x](::;$[x~`.qq.z.s;`.z.s;x])};
                // .z.s:enlist[.z.s],n#() in preamble
                x[2]:(";";(:;`.z.s;(,;(enlist;`.z.s);(#;count spill;())));
                          last visit[v;d;::;x 2]);
                ];
            ];
        (locals;x)
        };
    visitFuncs[(;);fd;(0#`)!0#0;x]
    };


profiling:0b; // enabled
profile:(); // results

profileCaller:0N;
profileTop:0#0b;
profileCall:{[n;f;args]
    if[top:profileTop n;
        profileTop[n]:0b];
    caller:profileCaller;
    profileCaller::n;
    t:.z.p;

    x:.['[';f];args;{({'x};x)}];

    t:.z.p-t;
    profileCaller::caller;
    profile[n;`calls`self]+:(1;t);
    if[top;
        profile[n;`top`total]+:(1;t);
        profileTop[n]:1b];
    if[not null caller;
        profile[caller;`self]-:t];

    get x
    };

tracing:0b; // enabled

traceDepth:0j;
traceCall:{[zs;n;f;args]
    dargs:zs _args; // don't display instrumented .z.s
    -2@((-1+traceDepth+:1)#" "),
        string[profile[n;`name]],"[",$[dargs~enlist(::);"";";"sv -3!'dargs],"]";
    x:.['[';f];args;{({'x};x)}];
    -2@((traceDepth-:1)#" "),$[0h=type x;"'",last x;":",-3!get x];
    get x
    };

// {...} -> {.qq.profileCall[0;{...};(...)]}
// It's possible to find every :exit, but not every 'signal (e.g. 'type can
// occur anywhere), so the whole function must be wrapped. This is also faster
// because it requires one global state update per call, not one per entry and
// one per exit.
instrumentFunctions:{
    if[not profiling|tracing;:x];
    if[profiling&tracing;'`nyi];
    fd:{[zs;x]
        if[(1<count x)&(0h=type x)&"{"~first x;
            n:count profile;
            profile,:enlist`name`calls`top`total`self!
                ($[3<count x;first x 3;`];0j;0j;00n;00n);
            profileTop,:1b;
            // pass .z.s of wrapper as extra param if needed; shadows local .z.s
            params:(zs#`.z.s),first x 1;
            x[2]:($[profiling;`.qq.profileCall;(`.qq.traceCall;zs)];
                  n;("{";enlist params;x 2);(enlist),params);
            ];
        if[x~`.z.s;
            zs:1b];
        (zs;x)
        };
    visitFuncs[(;);fd;0b;x]
    };


// NOTE: Order is important.
transforms:(
    multiAssign;parametricQueries;
    autoParams;functionNames;captureLocals;
    instrumentFunctions;
    moreParams;moreLocals);


literal:{
    $[99h=type x; // some compound literals have to be rendered as expressions
        "(",.z.s[key x],"!",.z.s[value x],")";
      (type[x]within 0 97h)&1=count x;
        "enlist[",.z.s[first x],"]";
      0=count x;
        "(",(-3!x),")";
      0h=type x;
        "(",(";"sv .z.s each x),")";
      1h=type x; // \c limits the total output, so compile atom by atom
        raze[string x],"b";
      4h=type x;
        "0x",raze string x;
      10h=type x;
        "\"",raze[-1_'1_'-3!'x],"\"";
      11h=type x;
        raze -3!'x;
      type[x]within 1 19h;
        (" "sv ?[""~/:s;count[s]#enlist"0N";s:string x]),.Q.ty x;
        "(",(-3!x),")"] // should not truncate with \c as set in compile[]
    };

expression:{
    $[(1<count x)&type[x]in 0 11h; // call
        $["{"~x 0;
            // In case of anonymous params ({[]...} -> {[captured;]...}), copy
            // names from left ({[captured;captured]...}): names in body refer
            // to first instance of parameter.
            "{",$[(::)~x 1;"";"[",(";"sv string fills first x 1),"]"],
                $[3<count x;literal first x 3;""],";",.z.s[x 2],"}";
          ";"~x 0;
            "[",(";"sv .z.s each 1_x),"]";
          any(":";"'")~\:x 0;
            x[0],.z.s x 1;
            (.z.s x 0),"[",(";"sv
              // watch out for special projection ::, as in parse"{}[::;]"
              (.z.s;{""})[count each 0#\:'1_x]@'1_x),"]"];
      (1=count x)&type[x]in 0 11h; // `sym escape
        literal first x;
      -11h=type x; // variable name
        string x;
      100h>type x;
        literal x;
      $[3>count -3!x;0b;not null op:.q?x]; // .q.verb
        string op;
        literal x]
    };

compile:{
    // -3! used in literal[] is subject to these settings
    P:system"P";c:system"c";
    system"P 17";system"c 25 2000";
    r:expression x;
    system"P ",-3!P;system"c ",-3!c;
    r};

e:{get compile parser[x] {y x}/transforms};
l:{{{if[not(::)~x;-1@.Q.s1 x]} e x;} each preprocess $[0h=type x;x;read0 x];};


// q qq.q [-profile output|-trace] [program.q]
main:{[]
    if[@[{[]x;1b};::;0b];:(::)]; // only run once
    x::.z.x; // can't modify .z.x
    if["-profile"~x 0;x _:0;
        profiling::1b;
        if[count x;
            .[`.z.exit;();{x set profile;y z}[:[x _:0]hsym`$x 0]]];
        ];
    if["-trace"~x 0;x _:0;
        tracing::1b];
    .z.pi:{show e x;};
    if[count x;
        l:[x _:0]hsym`$x 0];
    };

\d .

if[`qq.q=last` vs hsym .z.f;
    .qq.main[]];
