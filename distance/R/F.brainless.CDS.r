F.brainless.CDS <- function( dist, group.size=1, area, total.trans.len, w.lo=0, w.hi=max(dist), 
            likelihoods=c("halfnorm", "hazrate", "uniform","negexp","gamma"), 
            series=c("cosine", "hermite", "simple"), 
            expansions=0:3, plot=T ){
#
#   Automatically estimate a distance function and abundance 
#
#   Input:
#   dist = vector of perpendicular distances off transect
#   group.size = vector of group sizes for every element in dist
#   area = area of the study area, in units of u^2 (e.g., if u = meters, this is square meters)
#   total.trans.len = total length of all transects in the study area, in units of u (e.g., if u=methers, this is meters)
#   w.lo = minimum sighting distance from the transect.  Sometimes called left-truncation value. 
#   w.hi = maximum sighting distance off transect.  Sometimes called right-truncation value. 
#   likelihoods = vector of likelihoods to try
#   series = vector of series to try
#   expansions = vector of expansion terms to try
#
#   Output: 
#   A CDS object containing the best fitting sighting function selected from those 
#   fitted, and abundance estimates for that sighting function.
#

f.save.result <- function(results, dfunc, like, ser, expan, plot){
#   Internal function to print and plot and save results in a table
    aic = AIC(dfunc)
    conv <- dfunc$fit$convergence
    results <- rbind( results, data.frame( like=like, series=ser, expansions=expan, converge=conv, aic=aic))
    
    if( nchar(like) < 8 ) sep1 <- "\t\t" else sep1 <- "\t"
    
    if( conv != 0 ) aic <- NA
    
    cat( paste(like, sep1, ser, "\t\t", expan, "\t\t", conv, "\t\t", round(aic, 4), sep=""))

    if(plot){
        plot(dfunc, main=paste( like, ",", ser, " expansion, ", expan, " expansions", sep=""))
        k <- readline(" Enter to continue > ")
    } else {
        cat("\n")
    }

    results
}


fit.table <- NULL
cat("Likelihood\tSeries\t\tExpans\t\tConverged?\tAIC\n")
for( like in likelihoods){

    if( like == "gamma" ){
    
        #   No expansion terms or series (yet) for gamma likelihood
        dfunc <- F.dfunc.estim(dist, likelihood=like, w.lo=w.lo, w.hi=w.hi)
        ser <- ""
        expan <- 0

        fit.table <- f.save.result( fit.table, dfunc, like, ser, expan, plot )
         
    } else {
    
        #   Remaining likelihoods have series expansions
        for( expan in expansions){
            if( expan == 0 ){
            
                dfunc <- F.dfunc.estim(dist, likelihood=like, w.lo=w.lo, w.hi=w.hi, expansions=expan, series=ser)
                
                fit.table <- f.save.result( fit.table, dfunc, like, ser, expan, plot )
            } else {
                for( ser in series){
                
                    dfunc <- F.dfunc.estim(dist, likelihood=like, w.lo=w.lo, w.hi=w.hi, expansions=expan, series=ser)
                    
                    fit.table <- f.save.result( fit.table, dfunc, like, ser, expan, plot )
                }
            }
        }
    }
}


#-------------------
#   Now choose best distance function.  Re-fit, and estimate abundance

fit.table$aic <- ifelse(fit.table$converge == 0, fit.table$aic, Inf )
fit.table <- fit.table[ order(fit.table$aic), ]

dfunc <- F.dfunc.estim(dist, likelihood=fit.table$like[1], w.lo=w.lo, w.hi=w.hi, expansions=fit.table$expansions[1], series=fit.table$series[1])


if( plot ) plot(dfunc, main=paste( "BEST FITTING FUNCTION\n", fit.table$like[1], ",", fit.table$series[1], " expansion, ", fit.table$expansions[1], " expansions", sep=""))


cat("\n\n---------------- Brainless CDS Abundance estimate -------------------------------\n")
abund <- F.abund.estim( dfunc, group.size, area, total.trans.len )
print(abund)

if( sum( fit.table$converge != 0 ) > 0 ) cat("IGNORE ANY WARNINGS RESULTING FROM FAILED MODELS\n")

abund
}


# ----------------------------------------------------


