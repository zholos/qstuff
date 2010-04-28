/ solve.q: Different ways to solve a system of equations

/ Q Math Library from http://althenia.net/qml is required
\l qml.q

/ generate system of equations
n:1000;
while[0=.qml.mdet A:n cut .qml.nicdf .005+(n*n)?.99];
b:.qml.nicdf .005+n?.99;

/ solve by matrix inversion
/   Ax=b  =>  x=inv(A)b
1"inversion: ";
\t x1:.qml.minv[A]mmu b;

/ functions to solve Lx=b (forward substitution) and Ux=b (back substitution)
sub:{[I;U;b]
        {[U;b;x;i]@[x;i;:;(b[i]-x mmu U i)%U[i;i]]}[U;b]/[n#0.;I[n:count b]]};
fsub:sub[til];
bsub:sub[reverse@til@];

/ solve by QR factorization
/   Ax=b  <=>  QRx=b  =>  Rx=Q'b (R is triangular, solved by back substitution)
/   note: LAPACK initially returns Q in an intermediate form that could have
/   been used to calculate Q'b directly without incurring the delay of
/   constructing the full Q
1"QR:        ";
\t x2:bsub[QR 1;flip[(QR:.qml.mqr A)0]mmu b];

/ solve by QR factorization with column pivoting
/   APP'x=b  <=>  QRP'x=b  <=>  RP'x=Q'b  =>  Ry=Q'b, x=Py
1"QRP:       ";
\t x3:bsub[QRP 1;flip[QRP 0]mmu b]iasc(QRP:.qml.mqrp A)2;

/ solve by LUP factorization
/   Ax=b  <=>  PAx=Pb  <=>  LUx=Pb  <=>  Ly=Pb, Ux=y (L and U are triangular)
1"LUP:       ";
\t x4:bsub[LUP 1;fsub[LUP 0;b(LUP:.qml.mlup A)2]];

/ solve by Cholesky factorization
/   Ax=b  =>  A'Ax=A'b  <=>  R'Rx=A'b  <=>  R'y=A'b, Rx=y (R is triangular)
1"Cholesky:  ";
\t x5:bsub[R;fsub[flip[R:.qml.mchol A_ mmu A];(A_:flip A)mmu b]];

/ solve by singular value decomposition
/   Ax=b  <=>  USV'x=b  =>  x=V inv(S)U'b (S is diagonal)
1"SVD:       ";
\t x6:SVD[2]mmu(flip[SVD 0]mmu b)%(SVD:.qml.msvd A)[1]@'til n;

/ check results
if[1e-7<{max -1+(b%x)|x%b}A mmu x1;'`incorrect];
if[1e-5<max{max -1+(x1%x)|x%x1}each(x2;x3;x4;x5;x6);'`different];
