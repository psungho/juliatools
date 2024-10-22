capture program drop ipwDID
program ipwDID, rclass
    version 16.0
    // Define inputs: covariates (X), treatment (D), outcome period 1 (Y0), outcome period 2 (Y1)
    syntax varlist(numeric), treatment(varname) y0(varname) y1(varname)
    // Rescale lambda to match glmnet (lambda scaled by 2N)
    local lambda = 1000*_N*2
    // Fit propensity score using lasso2 with glmnet parameterization
    cap qui lasso2 `treatment' `varlist', lambda(`lambda') lglmnet
    // Predict propensity score
    qui predict double ehat, xb
    // Calculate inverse probability weighted difference-in-differences (ATT estimate)
    gen  ipw_did = (`treatment' - ehat) / (1 - ehat) * (`y1' - `y0')
    qui sum `treatment', meanonly
    scalar tmean = r(mean)
    qui sum ipw_did, meanonly
    scalar ipmean = r(mean)
    gen  att = (1/tmean) *ipmean
    qui sum att, meanonly
    return scalar ATT = r(mean)
    di "ATT Estimate (IPW-DID): " ATT
    cap drop att ipw_did ehat
end

capture program drop aipwDID
program aipwDID, rclass
    syntax varlist(numeric), treatment(varname) y0(varname) y1(varname)
    local lambda = 1000*_N*2
    // K-fold cross-validation
    local k_folds = floor(max(3, min(10, _N/4)))
    // Fit propensity score model using lasso2 (scaled lambda for glmnet)
    qui lasso2 `treatment' `varlist', lambda(`lambda') lglmnet
    qui predict double ehat, xb
    qui gen diff = `y1' - `y0'
    // Fit outcome model on control group (D == 0) using lasso2
    qui lasso2 diff `varlist' if `treatment' == 0, lambda(`lambda') lglmnet
    qui predict double mhat, xb
    // Calculate AIPW-DID
    qui sum `treatment', meanonly
    scalar tmean = r(mean)
    qui gen  aipw_did = ( diff/tmean) * (`treatment' - ehat) / (1 - ehat) - ((`treatment' - ehat) / tmean) * mhat / (1 - ehat)
    qui sum  aipw_did , meanonly
    scalar ATT = r(mean)
    di "ATT Estimate (AIPW-DID): " ATT
    cap drop ehat diff mhat aipw_did
end
