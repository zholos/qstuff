/ linreg.q: Linear regression routines

/ Q Math Library from http://althenia.net/qml is required
\l qml.q

/ ------------------------------------------------------------------------------
/ linreg[y;X]: Performs linear regression of y (vector) on X (list of vectors).
/   This function computes the least squares estimates of parameters and
/   covariance matrix and then calls linregtests to compute test statistics.
/.
/   e.g. exec linreg[price;(1.;sign;quantity)] from trades  / 1. for constant
/.   
/   Returns dictionary:
/     `X     = X (list of row vectors)
/     `y     = y (vector)
/     `S     = covariance matrix
/     `b     = parameter estimates
/     `e     = residuals
/     `n     = number of observations
/     `m     = number of parameters
/     `df    = degrees of freedom

linreg:{[y;X]
    if[any[null y:"f"$y]|any{any null x}'[X:"f"$X];'`nulls];
    if[$[0=m:count X;1;m>n:count X:flip X];'`length];
    e:y-X mmu b:(Z:.qml.minv[flip[X]mmu X])mmu flip[X]mmu y;
    linregtests ``X`y`S`b`e`n`m`df!(::;X;y;Z*mmu[e;e]%n-m;b;e;n;m;n-m)};


/ ------------------------------------------------------------------------------
/ linregtests[R]: Perform linear regression tests on a set of estimation
/   results. This function is called automatically by linreg, but can be called
/   again, for example, if the covariance matrix is adjusted. None of the values
/   returned by linreg are recalculated, in particular, if b is adjusted, e
/   needs to be recalculated.
/.
/   Updates R dictionary with:
/     `se    = standard error of estimates vector
/     `tstat = vector of t-statistics
/     `tpval = vector of p-values for t-test
/     `rss   = sum of squared residuals
/     `tss   = total sum of squares
/     `r2    = R-squared statistic
/     `r2adj = adjusted R-squared
/     `fstat = f-statistic
/     `fpval = p-value for f-test

linregtests:{[R]
    tstat:R[`b]%se:sqrt R[`S]@'til count R`S;
    fstat:(R[`df]*rss-tss:{x mmu x}R[`y]-+/[R`y]%R`n)%(1-R`m)*rss:e mmu e:R`e;
    R,`se`tstat`tpval`rss`tss`r2`r2adj`fstat`fpval!(se;tstat;
        2*1-R[`df] .qml.stcdf/:abs tstat;rss;tss;1-rss%tss;
        1-(rss*-1+R`n)%tss*R`df;fstat;1-.qml.fcdf[-1+R`m;R`df;fstat])};


/ ------------------------------------------------------------------------------
/ neweywest[R;lags]: Calculate Newey-West-adjusted covariance matrix.
/   This function updates `S in the R dictionary and calls linregtests to
/   update test statistics. Null lags sets them to n^(1/4).
/.
/   e.g. R:linreg[y;X];neweywest[R;0N]

neweywest:{[R;lags]
    L:$[lags>=0;lags;1|"i"$sqrt sqrt R`n];
    S:flip[X]mmu X:(R`X)*R`e;
    if[L>0;S:S+(+/)((L-til L)%1+L)*
        {[X;l]flip[X]+X:flip[l _X]mmu neg[l]_X}[X]'[1+til L]];
    linregtests R,enlist[`S]!enlist(Z mmu S)mmu Z:.qml.minv flip[R`X]mmu R`X};
