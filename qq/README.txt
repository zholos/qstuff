qq is an implementation of a modified dialect of q in q.

It parses source code into a syntax tree (including nested function bodies),
applies some transformations, and compiles it back to source code for q to run.

(Yes, it can compile itself.)

.qq.e["{source}"] evaluates an expression and .qq.l[`:program.q] runs a file.

Command-line usage: q qq.q [-profile output|-trace] program.q
Interactive mode: q qq.q

Features:
* capture values from lexical scope: {a:5;{a+x}[6]}[]
* multiple assignment: a..b..c:1 2 3
* parametric q-sql: {[grp]select sum q by .grp. from t}[`mkt]
* more function params and locals
* instrumented profiling: .qq.profiling:1b;.qq.l`:program.q;show .qq.profile;
* instrumented tracing: .qq.tracing:1b;.qq.l`:program.q;

Planned:
* object-oriented programming (maybe)
