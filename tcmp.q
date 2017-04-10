/ tcmp.q: cmp for tables

/ ------------------------------------------------------------------------------
/ tcmp[x;y]: Find positional differences between x to y
/ tcmpx[opt;x;y]
/.
/ Arguments:
/   x, y: tables with matching key types or no keys
/   opt: options
/     `show: show each item
/.
/ Returns dictionary:
/   `xcols: columns in x but not in y
/   `ycols: columns in y but not in x
/   `xkey:  row keys in x but not in y
/   `ykey:  row keys in y but not in x
/   `pairs: x and y values where they differ

tcmpx:{[opt;x;y]
    if[count ((),opt) except ``show;'"opt: unknown options"];
    if[any {98h<>type $[99h=type x;value x;x]} each (x;y);'"type: not a table"];
    if[98h=type x;x:til[count x]!x];
    if[98h=type y;y:til[count y]!y];

    / list and drop columns not common to x and y
    Cols:Cols except\:pCols:(inter). Cols:{cols value x} each (x;y);
    x:pCols#/:x;
    y:pCols#/:y;

    / list and drop rows not common to x and y
    / handle identical keys like in x+'y: don't reindex to allow duplicates
    / but keep order for different keys, unlike x+'y
    $[(~). Key:key each (x;y);[
        pKey:Key 0;
        Key:0#'Key;
        x:flip value x;
        y:flip value y;
    ];[
        Key:Key except\:pKey:(inter). Key;
        x:flip x pKey;
        y:flip y pKey;
    ]];
    / x and y are now column dictinaries aligned to pKey

    $[x~y;[
        / special case since can't make table with no columns
        pairs:();
    ];[
        / drop identical columns and rows
        x@:pCols:where not x~'y;
        y@:pCols;

        / combine columns from both tables and blank out identical value pairs
        i:where not all same:x~''y; / rows to keep
        pairs:pKey[i]!flip (` sv'raze pCols,/:\:`x`y)!
            raze flip (x;y)@'\: same {?[x y;0N;y]}\:i;
    ]];

    if[`show in opt;
        if[count Cols 0;-1"xcols: ",-3!Cols 0;-1""];
        if[count Cols 1;-1"ycols: ",-3!Cols 1;-1""];
        if[count Key 0;-1"xkey:";show Key 0;-1""];
        if[count Key 1;-1"ykey:";show Key 1;-1""];
        if[count pairs;-1"pairs:";show pairs];
        :(::)];

    `xcols`ycols`xkey`ykey`pairs!Cols,Key,enlist pairs
    };

tcmp:tcmpx`;

/ example:
/
t0:([sym:`AAA`AAA`AAA`BBB`BBB;
     time:09:00 09:15 09:30 09:00 09:30]
     pb:101 102 103 501 502.;
     qb:1000 2000 1000 10 10;
     pa:101.5 102.25 103.75 503.5 503;
     qa:500 5000 1000 10 20;
     cond:"NRNRR";
     seq:til 5);
t1:([sym:`AAA`AAA`AAA`BBB`BBB;
     time:09:10 09:15 09:30 09:00 09:30]
     pb:101 102 103 501.75 502;
     qb:1000 2000 1000 10 10;
     pa:101.75 102.5 103.75 503.5 503;
     qa:500 5000 1250 10 20;
     cond:"NRRRR");
tcmpx[`show;t0;t1]
