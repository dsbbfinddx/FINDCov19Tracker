% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/test-data.R
\name{combine_all_tests}
\alias{combine_all_tests}
\title{Combine test daily data from all countries across all dates}
\usage{
combine_all_tests()
}
\description{
This function reads all clean input files from the \href{https://github.com/dsbbfinddx/FINDCov19TrackerData/tree/master/automated/merged}{automated/merged} directory and row-binds them. The output is written to a file called
\code{coronavirus_tests_new.csv} and uploaded to \code{automated/coronavirus_tests_new.csv}.
}
