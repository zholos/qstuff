/ tdiff.q: diff for tables

/ ------------------------------------------------------------------------------
/ tdiff[x;y]: Construct a table showing changes from x to y.
/ tdiffx[context;x;y]: Take only context lines from runs of matches.

tdiffx:{[context;x;y]
    if[not(~). 0#'t:0!'(x;y);'`mismatch];

    / special cases
    if[any 0=n:count'[t];:{0!([]y#x)!z}.("-+";n;t)[;0=n 0]];
    
    / Hunt-McIlroy diff algorithm
    c:{x[2;i:1+i]:flip x[;i:i k:where differ i:i j:where z<>x[1]i:x[1]bin z];
        x[1;i]:z j k;x[0;i]:y;x}/[min[n]#'(0W;0W;enlist 0#0);
        i;r i:where 0<count'[r:group[y]x]];
    c:2#flip 1_reverse(not null first@)last\c[;-1+c[0]?0W];
    
    / construct diff
    c:where[any 1<>deltas'[0N;c]]_/:c;
    r:{i+til each(y[;0],x)-i:0,1+last'[y]}'[n;c];
    i:(flip((();1#0N)0b,p;enlist[()],((::;neg[0|context]#)p)@'c 0;r 0);
       flip(r 1;(((0;0|context)p:context<div[1+count'[c 0];2])#'c 1),enlist()));
    0!([]raze raze raze'[flip count'''[i]]#'\:". -+ ")!
         raze raze flip t@'raze''[i]};

tdiff:tdiffx[0W];
