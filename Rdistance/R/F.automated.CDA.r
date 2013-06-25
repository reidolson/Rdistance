F.automated.CDA <- function( dist, group.size=1, area=1, total.trans.len=1, w.lo=0, w.hi=max(dist),
            likelihoods=c("halfnorm", "hazrate", "uniform","negexp","Gamma"),
            series=c("cosine", "hermite", "simple"),
            expansions=0:3, plot=TRUE, ... ){
#
#   Automatically estimate a distance function and abundance
#
#   Input:
#   dist = vector of perpendicular distances off transect
#   group.size = vector of group sizes for every element in dist, replicated as necessary
#   area = area of the study area, in units of u^2 (e.g., if u = meters, this is square meters)
#   total.trans.len = total length of all transects in the study area, in units of u (e.g., if u=methers, this is meters)
#   w.lo = minimum sighting distance from the transect.  Sometimes called left-truncation value.
#   w.hi = maximum sighting distance off transect.  Sometimes called right-truncation value.
#   likelihoods = vector of likelihoods to try
#   series = vector of series to try
#   expansions = vector of expansion terms to try
#   ... = parameters passed on to F.dfunc.estim, which are inturn passed onto F.gx.estim.  These 
#       include x.scl, g.x.scl, and observer for estimating double observer probabilities. 
#
#   Output:
#   A CDS object containing the best fitting sighting function selected from those
#   fitted, and abundance estimates for that sighting function.
#

f.save.result <- function(results, dfunc, like, ser, expan, plot){
#   Internal function to print and plot and save results in a table

    esw <- ESW(dfunc)
    if( !is.na(esw) & (esw > dfunc$w.hi) ){
        scl.ok <- "Not ok"
        scl.ok.flag <- 0
        aic <- NA
    } else {
        scl.ok <- "Ok"
        scl.ok.flag <- 1
        aic = AIC(dfunc)
    }
    conv <- dfunc$convergence
    if( conv != 0 ) {
        if(conv == -1){
            conv.str <- "Bad"  # this is 'solution failure', parameters at the boundary
        } else {
            conv.str <- "No"   # Just did not converge
        }
        aic <- NA
        scl.ok <- "NA"
        scl.ok.flag <- NA
    } else {
        conv.str <- "Yes"
    }

    results <- rbind( results, data.frame( like=like, series=ser, expansions=expan, converge=conv, 
        scale=scl.ok.flag, aic=aic))

    if( nchar(like) < 8 ) sep1 <- "\t\t" else sep1 <- "\t"

    cat( paste(like, sep1, ser, "\t", expan, "\t", conv.str, "\t\t", scl.ok, "\t", round(aic, 4), sep=""))

    if(plot){
        plot(dfunc)
        k <- readline(" Next?[entr=y,n]")
        if( length(k) == 0 ) k <- "y"   # allows user to just hit enter
    } else {
        cat("\n")
        k <- "y"
    }

    list(results=results, k=k)
}

wwarn <- options()$warn
options(warn=-1)

fit.table <- NULL
cat("Likelihood\tSeries\tExpans\tConverged?\tScale?\tAIC\n")
for( like in likelihoods){

    if( like == "Gamma" ){

        #   No expansion terms or series (yet) for gamma likelihood
        dfunc <- F.dfunc.estim(dist, likelihood=like, w.lo=w.lo, w.hi=w.hi, ...)
        ser <- ""
        expan <- 0

        fit.table <- f.save.result( fit.table, dfunc, like, ser, expan, plot )
        cont <- fit.table$k
        fit.table <- fit.table$results


    } else {

        #   Remaining likelihoods have series expansions
        for( expan in expansions){
            if( expan == 0 ){

                ser <- "cosine"  # does not matter because expan == 0
                dfunc <- F.dfunc.estim(dist, likelihood=like, w.lo=w.lo, w.hi=w.hi, expansions=expan, series=ser, ...)

                fit.table <- f.save.result( fit.table, dfunc, like, ser, expan, plot )
                cont <- fit.table$k
                fit.table <- fit.table$results

            } else {
                for( ser in series){

                    dfunc <- F.dfunc.estim(dist, likelihood=like, w.lo=w.lo, w.hi=w.hi, expansions=expan, series=ser, ...)

                    fit.table <- f.save.result( fit.table, dfunc, like, ser, expan, plot )
                    cont <- fit.table$k
                    fit.table <- fit.table$results

                    if( cont == "n" ) break
                }
            }
            if( cont == "n" ) break
        }
        if( cont == "n" ) break
    }
}


#-------------------
#   Now choose best distance function.  Re-fit, and estimate abundance

if( sum( fit.table$converge != 0 ) > 0 ) cat("Note: Some models did not converge or had parameters at their boundaries.\n")

fit.table$aic <- ifelse(fit.table$converge == 0, fit.table$aic, Inf )
fit.table <- fit.table[ order(fit.table$aic), ]

dfunc <- F.dfunc.estim(dist, likelihood=fit.table$like[1], w.lo=w.lo, w.hi=w.hi, expansions=fit.table$expansions[1], series=fit.table$series[1], ...)

if( plot ) {
    plot(dfunc)
    mtext("BEST FITTING FUNCTION", side=3, cex=1.5, line=3)
}

if( missing( group.size )){
    abund <- F.abund.estim( dfunc, avg.group.size=1, area=area, tot.trans.len=total.trans.len )
} else {
    abund <- F.abund.estim( dfunc, group.sizes=group.size, area=area, tot.trans.len=total.trans.len )
}
cat("\n\n---------------- Final Automated CDS Abundance estimate -------------------------------\n")
print(abund)


options(warn=wwarn)

abund
}


# ----------------------------------------------------
