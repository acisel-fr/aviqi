% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/load-data.R
\name{getColumnTypes}
\alias{getColumnTypes}
\title{Get column types}
\usage{
getColumnTypes(hasIds, table)
}
\arguments{
\item{hasIds}{A boolean identifying a table with a column id}

\item{table}{The table type}
}
\value{
Vector of column types
}
\description{
Identify column types based on the table type: c for character, i for integer…
}
