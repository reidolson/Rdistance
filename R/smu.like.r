#' @name smu.like
#' 
#' @title Smoothed likelihood function for distance analyses
#' 
#' @description This function computes the likelihood (height of the smooth)
#' for 
#' sighting distances, scaled appropriately, for use as a 
#' distance likelihood.
#' 
#' @param a A data frame containing the smooth.  This data frame 
#' must contain at least an \code{$x} and \code{$y} components. 
#' These components are generally the output of function \code{stats::density}.
#' 
#' @param dist A numeric vector containing the observed distances.
#' 
#' @param w.lo Scalar value of the lowest observable distance.  
#' This is the \emph{left truncation} of sighting distances 
#' in \code{dist}. Same units as \code{dist}. Values less than 
#' \code{w.lo} are allowed in \code{dist}, but are ignored and 
#' their contribution to the likelihood is set to \code{NA} in the output.
#' 
#' @param w.hi Scalar value of the largest observable distance.  
#' This is the \emph{right truncation} of sighting distances 
#' in \code{dist}.  Same units as \code{dist}. Values greater 
#' than \code{w.hi} are allowed in \code{dist}, but are ignored 
#' and their contribution to the likelihood is set to \code{NA} 
#' in the output.
#' 
#'   
#' @param scale Logical scaler indicating whether or not to 
#' scale the likelihood so it integrates to 1. This parameter is 
#' used to stop recursion in other functions. If \code{scale} 
#' equals TRUE, a numerical integration routine 
#' (\code{\link{integration.constant}}) is called, which in turn 
#' calls this likelihood function again with \code{scale} = FALSE. 
#' Thus, this routine knows when its values are being used to compute 
#' the likelihood and when its value is being used to compute the 
#' constant of integration.  All user defined likelihoods must have 
#' and use this parameter.
#' 
#' @param pointSurvey Boolean. TRUE if distances in \code{dist} are 
#' radial from point 
#' transects, FALSE if distances are perpendicular off-transect distances.
#' 
#' @details The \code{\link{base::approx}} function is used to evaluate 
#' the funnction.  Distances outside the range \code{w.lo} to \code{w.hi} are 
#' set to \code{NA}. 
#'   
#' @return A numeric vector the same length and order as \code{dist} containing the 
#' likelihood contribution (height of the smoothed function) for 
#' corresponding distances in \code{dist}. 
#' Assuming \code{L} is the vector returned by this function, 
#' the negative log likelihood of all the data is \code{-sum(log(L), na.rm=T)}. 
#' Note that the returned likelihood value for distances less 
#' than \code{w.lo} or greater than \code{w.hi} is \code{NA}, 
#' hence \code{na.rm=TRUE} in the sum. 
#' If \code{scale} = TRUE, the integral of the likelihood from
#'  \code{w.lo} to \code{w.hi} is 1.0. If \code{scale} = FALSE, 
#'  the integral of the likelihood is something else.
#'  
#' @author Trent McDonald, WEST, Inc. \email{tmcdonald@west-inc.com}
#'         
#' @seealso \code{\link{dfuncSmu}},
#'          \code{\link{hazrate.like}},
#'          \code{\link{uniform.like}},
#'          \code{\link{negexp.like}},
#'          \code{\link{halfnorm.like}}
#'          
#' @examples  \dontrun{
#' set.seed(238642)
#' d <- abs(rnorm(100))
#' dfunc <- dfuncSmu(d~1)
#' 
#' L <- smu.like(a=dfunc$parameters, dist=dfunc$dist, w.lo=dfunc$w.lo, 
#'    w.hi=dfunc$w.hi, scale=TRUE)
#' -sum(log(L), na.rm=TRUE)  # the negative log likelihood
#' }
#' @keywords models
#' @export

smu.like <- function(a, dist, w.hi, w.lo = 0, 
                     scale = TRUE, 
                     pointSurvey = FALSE, ...){
  
  # evaluate dfunc, which is ($x,$y) in a.dataFrame, at x. 
  dfunc <- approx(a$x, a$y, xout=dist, rule=1)$y
  
  if( scale ){
    scl <- integration.constant(dist, smu.like, 
                                w.lo=w.lo, w.hi=w.hi, a=a,
                                pointSurvey = pointSurvey, ...)  
    dfunc = dfunc / scl 
  }
  c(dfunc)
}
