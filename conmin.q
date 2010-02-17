/ conmin.q: Optimization examples

/ Q Math Library from http://althenia.net/qml is required
\l qml.q

/ different ways to solve an equation
f:{(x*exp x)-2};               / equation: x e^x=2
.qml.root[f;0 1]               / univariate search on interval (0;1)
.qml.solve[f;0]                / generic solving starting at 0
.qml.line[{x*x}f@;0;1]         / line search for minimum of (x e^x-2)^2 from 0
.qml.conmin[{x};f,(neg f@);0]  / minimize x s.t. x e^x>=2 and x e^x<=2

/ different ways to find an unconstrained minimum
f:{x*exp[x]-2};       / function: x e^x-2x
.qml.line[f;0;1]      / line search for minimum from 0 in positive direction
.qml.min[f;0]         / generic minimization starting at 0
nd:{(x[y+h]-x y)%h:sqrt .qml.eps};
.qml.root[nd[f];0 1]  / find zero of first derivative on interval (0;1)
.qml.solve[nd[f];0]   / generic solving for zero of first derivative


/ more equations
n:25;                              / a small linear system
while[0=.qml.mdet A:n cut .qml.nicdf .005+(n*n)?.99];
b:.qml.nicdf .005+n?.99;           / Ax=b
f:{y-x mmu z}./:flip(A;b);         / a function for each equation
x:first .qml.solve[f;enlist n#0];x / parameter length matches function valence
max abs x-.qml.minv[A]mmu b        / compare to solution by matrix inversion

f:{25-(x*x)+y*y},{y-1+x%16 xexp reciprocal x}; / a nonlinear system
.qml.solve[f;1 0]                 / solution
.qml.solvex[`full`quiet;f;-1 -1]  / not all points converge to the solution

p:(-1 0 1 2 3;0 10 30 36 28);        / some point coordinates
f:{1-last x},{y-sum(x xexp til 6)*}'[p 0;p 1];
c:first .qml.solve[f;enlist 6#0];c   / run a 5th degree polynomial through them
.qml.poly c                          / one of the roots should be -1


/ more optimization
f:{(a*a:1-x)+100*b*b:y-x*x};       / Rosenbrock function
.qml.minx[`full`iter,10000;f;5 5]  / needs more iterations to converge

f:{(x*x*x*x)+y*(3*x*1+x*6)+y*y*y-8};      / function with multiple local minima
g:-10+til 21;                             / grid points
m:{.qml.minx[`quiet;f;x,y]}\:/:[g;g];     / minimize from different points
asc[distinct raze v]?v:floor f ./:/:m     / see which points gave which minimum
l first where v=min v:f ./:l:raze m       / pick global minimum

f:{neg(5*x)+(3*y)+7*z};                   / linear objective function
c:{z;10-(2*x)+4*y},{15-(3*z)-y},{9-x+y+z},{z;x},{z;y},{z};  
.qml.conminx[`lincon;f;c;0 0 0]           / linear constraints


/ calculate bond yield to maturity
npv:{[cf;t;r]sum cf*exp neg r*t};              / net present value
irr:{[cf;t].qml.rootx[`quiet;npv[cf;t];0 1]};  / internal rate of return
yield:{[p;c;T]irr["f"$neg[p],100,n#c%2;"f"$0,T,t:T-.5*til n:ceiling T*2]};

yield[98;5;3.5]                                / price, coupon, years


/ find some portfolios on the efficient frontier (parametrized by q)
effport:{[r;Sigma;q]
    f:{[r;Sigma;q;w](w mmu Sigma mmu w)-q*r mmu w}[r;Sigma;q];
    cons:({y x}@/:til count r),{sum[x]-1},{1-sum x};
    w:first .qml.conminx[`lincon;f;cons;enlist count[r]#0];
    `r`s`w!(r mmu w;sqrt w mmu Sigma mmu w;w)};

r:.1 .25 .05;
Sigma:(.01 .02 -.003;.02 .2 -.004;-.003 -.004 .001);
effport[r;Sigma]each til[20]%70
