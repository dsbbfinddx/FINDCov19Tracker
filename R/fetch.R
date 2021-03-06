#' @importFrom rio import
#' @importFrom stats na.omit time
# fetch_from_csv <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA
#   proc_backlog <- ifelse(is.na(dots$backlog), 0, as.numeric(dots$backlog))

#   if (!is.na(dots$date_format)) { # for now only Costa Rica, updated day before
#     yesterday_char <- as.character(Sys.Date() - 1, dots$date_format)
#     dots$data_url <- gsub("DATE", yesterday_char, dots$data_url)
#   }

#   data <- rio::import(dots$data_url, format = "csv")

#   # remove missing data
#   # this removes rows which only have NA or "" in all columns
#   data <- data %>%
#     janitor::remove_empty(which = c("rows", "cols"))

#   if (!is.na(dots$xpath_cumul)) {
#     seps <- c(
#       stringr::str_extract(dots$xpath_cumul, "[,;]"),
#       stringr::str_extract(dots$xpath_new, "[,;]")
#     )
#     sep <- seps[which(!is.na(seps))]
#     idx <- unlist(stringr::str_split(dots$xpath_cumul, sep))

#     ### account for some special cases
#     # The following columns are dropped in favor of shorter versions of the same.
#     # Keeping both leads to clashes with the used regex down the line
#     data <- data %>%
#       dplyr::select_if(!(names(.) %in% c("totalTestResultsIncrease", "TESTS_ALL_POS")))

#     cols <- grep(idx[[2]], names(data))
#     data[, cols] <- sapply(data[, cols], as.numeric)
#     type <- idx[[1]]
#     if (type == "last") {
#       tests_cumulative <- data[nrow(data), cols]
#     } else if (type == "sum") {
#       tests_cumulative <- sum(na.omit(data[, cols]))
#     } else {
#       tests_cumulative <- data[as.integer(type), cols]
#     }
#     tests_cumulative <- as.numeric(tests_cumulative)
#     tests_cumulative <- tests_cumulative + proc_backlog
#     checkmate::assert_numeric(tests_cumulative, max.len = 1)
#   }

#   if (!is.na(dots$xpath_new)) {
#     seps <- c(
#       stringr::str_extract(dots$xpath_cumul, "[,;]"),
#       stringr::str_extract(dots$xpath_new, "[,;]")
#     )
#     sep <- seps[which(!is.na(seps))]
#     idx <- unlist(stringr::str_split(dots$xpath_new, sep))
#     cols <- grep(idx[[2]], names(data))
#     data[, cols] <- sapply(data[, cols], as.numeric)
#     type <- idx[[1]]
#     if (type == "last") {
#       new_tests <- data[nrow(data), cols]
#     } else if (type == "sum") {
#       new_tests <- sum(na.omit(data[, cols]))
#     } else {
#       new_tests <- data[as.integer(type), cols]
#     }
#     new_tests <- as.numeric(new_tests)
#     checkmate::assert_numeric(new_tests, max.len = 1)
#   }

#   if (is.na(dots$xpath_new)) {
#     new_tests <- calculate_new_tests(dots, tests_cumulative)
#   }

#   return(c(new_tests, tests_cumulative))
# }

# #' @importFrom utils download.file tail unzip
# fetch_from_xlsx <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA
#   proc_backlog <- ifelse(is.na(dots$backlog), 0, as.numeric(dots$backlog))

#   tmpfile <- tempfile("country_data", fileext = ".xlsx")

#   if (!is.na(dots$date_format)) {
#     today_char <- as.character(Sys.Date(), dots$date_format)
#     yesterday_char <- as.character(Sys.Date() - 1, dots$date_format)

#     tryCatch(
#       {
#         download.file(gsub("DATE", today_char, dots$data_url),
#           destfile = tmpfile, quiet = TRUE, mode =
#             "wb"
#         )
#       },
#       silent = FALSE,
#       condition = function(err) { }
#     )
#     if (file.size(tmpfile) == 0) {
#       tryCatch(
#         {
#           download.file(gsub("DATE", yesterday_char, dots$data_url),
#             destfile = tmpfile, quiet = TRUE
#           )
#         },
#         silent = FALSE,
#         condition = function(err) { }
#       )
#       if (file.size(tmpfile) == 0) {
#         return(c(new_tests, tests_cumulative))
#       }
#     }
#   } else {
#     tryCatch(
#       {
#         download.file(url,
#           destfile = tmpfile, quiet = TRUE
#         )
#       },
#       silent = FALSE,
#       condition = function(err) { }
#     )
#     if (file.size(tmpfile) == 0) {
#       return(c(new_tests, tests_cumulative))
#     }
#   }

#   data <- readxl::read_excel(tmpfile, sheet = 1, progress = FALSE)
#   sep <- ","

#   if (!is.na(dots$xpath_cumul)) {
#     seps <- c(
#       stringr::str_extract(dots$xpath_cumul, "[,;]"),
#       stringr::str_extract(dots$xpath_new, "[,;]")
#     )
#     sep <- seps[which(!is.na(seps))]
#     idx <- unlist(stringr::str_split(dots$xpath_cumul, sep))

#     # account for some special cases
#     # - totalTestResultsIncrease is dropped in favor of totalTestResults, which
#     # would lead to clashes down the road
#     data <- data %>%
#       dplyr::select_if(!(names(.) %in% c("totalTestResultsIncrease")))

#     cols <- grep(idx[[2]], names(data))
#     data[, cols] <- sapply(data[, cols], as.numeric)
#     type <- idx[[1]]
#     if (type == "last") {
#       tests_cumulative <- data[nrow(data), cols]
#     } else if (type == "sum") {
#       tests_cumulative <- sum(na.omit(data[, cols]))
#     } else {
#       tests_cumulative <- data[as.integer(type), cols]
#     }
#     tests_cumulative <- as.numeric(tests_cumulative)
#     tests_cumulative <- tests_cumulative + proc_backlog
#     checkmate::assert_numeric(tests_cumulative, max.len = 1)
#   }

#   if (!is.na(dots$xpath_new)) {
#     seps <- c(
#       stringr::str_extract(dots$xpath_cumul, "[,;]"),
#       stringr::str_extract(dots$xpath_new, "[,;]")
#     )
#     sep <- seps[which(!is.na(seps))]
#     idx <- unlist(stringr::str_split(dots$xpath_new, sep))
#     cols <- grep(idx[[2]], names(data))
#     data[, cols] <- sapply(data[, cols], as.numeric)
#     type <- idx[[1]]
#     if (type == "last") {
#       new_tests <- data[nrow(data), cols]
#     } else if (type == "sum") {
#       new_tests <- sum(na.omit(data[, cols]))
#     } else {
#       new_tests <- data[as.integer(type), cols]
#     }
#     new_tests <- as.numeric(new_tests)
#     checkmate::assert_numeric(new_tests, max.len = 1)
#   }

#   if (is.na(dots$xpath_new)) {
#     new_tests <- calculate_new_tests(dots, tests_cumulative)
#   }

#   return(c(new_tests, tests_cumulative))
# }

# fetch_from_json <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA

#   getData <- httr::GET(dots$data_url)
#   getData_text <- httr::content(getData, "text", encoding = "UTF-8")
#   getData_json <- jsonlite::fromJSON(getData_text, flatten = TRUE)

#   if (!is.na(dots$xpath_cumul)) {
#     # FIXME: prefix namespace of last so we do not need to import all of dplyr
#     # because of "dplyr::last()" embedded in xpath_cumul
#     # library(dplyr)
#     tests_cumulative <- as.numeric(eval(parse(text = dots$xpath_cumul)))
#   }
#   if (!is.na(dots$xpath_new)) {
#     new_tests <- as.numeric(eval(parse(text = dots$xpath_new)))
#   }

#   if (is.na(dots$xpath_new)) {
#     new_tests <- calculate_new_tests(dots, tests_cumulative)
#   }

#   return(c(new_tests, tests_cumulative))
# }

# is.error <- function(x) inherits(x, "try-error")

# fetch_from_html <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA

#   page <- try(xml2::read_html(dots$source), silent = TRUE)
#   if (is.error(page)) {
#     page <- try(xml2::read_html(url(dots$source)), silent = TRUE)
#     if (is.error(page)) {
#       return(c(new_tests, tests_cumulative))
#     }
#   }

#   if (!is.na(dots$xpath_cumul)) {
#     text <- page %>%
#       rvest::html_node(xpath = dots$xpath_cumul) %>%
#       rvest::html_text()

#     if (!grepl(",|\\.|+|\\(|\\)|[[:blank:]]", text)) {
#       tests_cumulative <- as.numeric(gsub("[[:blank:]]", "", text))
#     } else {
#       tests_cumulative <- as.numeric(
#         gsub(",|\\.|+|\\(|\\)|[[:blank:]]",
#           replacement = "",
#           stringr::str_extract(text, "[0-9].*.*")
#         )
#       )
#     }
#   }
#   if (!is.na(dots$xpath_new)) {
#     text <- page %>%
#       rvest::html_node(xpath = dots$xpath_new) %>%
#       rvest::html_text()

#     if (!grepl(",|\\.|+|\\(|\\)|[[:blank:]]", text)) {
#       new_tests <- as.numeric(gsub("[[:blank:]]", "", text))
#     } else {
#       new_tests <- as.numeric(
#         gsub(",|\\.|+|\\(|\\)|[[:blank:]]",
#           replacement = "",
#           stringr::str_extract(text, "[0-9].*.*")
#         )
#       )
#     }
#   }

#   if (is.na(dots$xpath_new)) {
#     new_tests <- calculate_new_tests(dots, tests_cumulative)
#   }

#   return(c(new_tests, tests_cumulative))
# }

fetch_from_pdf <- function(dots) {

  # if (!dots$country == "Switzerland") {
  #   stop(sprintf(
  #     "Country %s is not supported yet for PDF extraction.",
  #     dots$country
  #   ))
  # }

  tests_cumulative <- NA
  new_tests <- NA

  tmpfile <- tempfile("country_data", fileext = ".pdf")

    tryCatch(
      {
        download.file(dots$source,
          destfile = tmpfile, quiet = TRUE,
        )
      },
      silent = FALSE,
      condition = function(err) { }
    )
    if (file.size(tmpfile) == 0) {
      return(c(new_tests, tests_cumulative))
    }

  content <- pdftools::pdf_text(tmpfile)

  tests_cumulative <- na.omit(
    as.numeric(
      stringr::str_replace_all(
        stringr::str_extract(stringr::str_squish(
          content
        ), dots$xpath_cumul),
        "[.]|[,]", ""
      )
    )
  )

  new_tests <- na.omit(
    as.numeric(
      stringr::str_replace_all(
        stringr::str_extract(stringr::str_squish(
          content
        ), dots$xpath_new),
        "[.]|[,]", ""
      )
    )
  )

  # in case something goes wrong, we fall back to the manual calculation of new_tests
  if (length(new_tests) == 0) {
    dots$xpath_new <- NA
  }

  if (is.na(dots$xpath_new)) {
    new_tests <- calculate_new_tests(dots, tests_cumulative)
  }

  return(c(new_tests, tests_cumulative))
}

fetch_from_pdf_list <- function(dots) {
  tests_cumulative <- NA
  new_tests <- NA

  tests_cumulative <- tryCatch(
    {
      page <- xml2::read_html(dots$source)
      hrefs <- rvest::html_attr(rvest::html_nodes(page, "a"), "href")

      pdfs <- grep(dots$data_url, hrefs, ignore.case = TRUE, value = TRUE)

      pdf <- pdfs[1]

      content <- pdftools::pdf_text(pdf)

      tests_cumulative <- na.omit(
        as.numeric(
          stringr::str_replace_all(
            stringr::str_extract(stringr::str_squish(
              content
            ), dots$xpath_cumul),
            "[.]|[,]", ""
          )
        )
      )
    },
    error = function() {
      cli::cli_alert_danger("Getting {.field tests_cumulative} failed for
        country {.field {dots$country}}.", wrap = TRUE)
      return(NA)
    }
  )

  new_tests <- tryCatch(
    {
      new_tests <- na.omit(
        as.numeric(
          stringr::str_replace_all(
            stringr::str_extract(stringr::str_squish(
              content
            ), dots$xpath_new),
            "[.]|[,]", ""
          )
        )
      )
    },
    error = function() {
      cli::cli_alert_danger("Getting {.field new_tests} failed for country
        {.field {dots$country}}.", wrap = TRUE)
      return(NA)
    }
  )

  if (is.na(dots$xpath_new)) {
    new_tests <- calculate_daily_tests_r_fetch(dots, tests_cumulative)
  }

  return(c(new_tests, tests_cumulative))
}

# fetch_from_html_list <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA

#   page <- xml2::read_html(dots$source)
#   hrefs <- rvest::html_attr(rvest::html_nodes(page, "a"), "href")

#   urls <- grep(dots$data_url, hrefs, ignore.case = TRUE, value = TRUE)

#   url <- urls[1]

#   content <- xml2::read_html(url) %>%
#     rvest::html_text()
#   tests_cumulative <- as.numeric(
#     stringr::str_replace_all(
#       (na.omit(stringr::str_extract(
#         stringr::str_squish(content),
#         dots$xpath_cumul
#       ))),
#       "[.]|[,]", ""
#     )
#   )

#   new_tests <- as.numeric(
#     stringr::str_replace_all(
#       (na.omit(stringr::str_extract(
#         stringr::str_squish(content),
#         dots$xpath_new
#       ))),
#       "[.]|[,]", ""
#     )
#   )

#   if (is.na(dots$xpath_new)) {
#     new_tests <- calculate_new_tests(dots, tests_cumulative)
#   }

#   return(c(new_tests, tests_cumulative))
# }

# fetch_from_html2 <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA


#   if (!is.na(dots$date_format)) {
#     today_char <- as.character(Sys.Date(), dots$date_format)
#     yesterday_char <- as.character(Sys.Date() - 1, dots$date_format)

#     page <- try(xml2::read_html(gsub("DATE", today_char, dots$data_url)),
#       silent = TRUE
#     )
#     if (is.error(page)) {
#       page <- try(xml2::read_html(gsub("DATE", yesterday_char, dots$data_url)),
#         silent = TRUE
#       )
#       if (is.error(page)) {
#         return(c(new_tests, tests_cumulative))
#       }
#     }

#   } else {
#     page <- try(xml2::read_html(dots$data_url), silent = TRUE)
#     if (is.error(page)) {
#       page <- try(xml2::read_html(url(dots$data_url)), silent = TRUE)
#       if (is.error(page)) {
#         return(c(new_tests, tests_cumulative))
#       }
#     }
#   }
#   content <- page %>%
#     rvest::html_text()

#   tests_cumulative <- as.numeric(
#     stringr::str_replace_all(
#       stringr::str_extract(stringr::str_squish(
#         content
#       ), dots$xpath_cumul),
#       "[.]|[,]", ""
#     )
#   )

#   new_tests <- as.numeric(
#     stringr::str_replace_all(
#       stringr::str_extract(stringr::str_squish(
#         content
#       ), dots$xpath_new),
#       "[.]|[,]", ""
#     )
#   )

#   if (is.na(dots$xpath_new)) {
#     new_tests <- calculate_daily_tests_r_fetch(dots, tests_cumulative)
#   }

#   return(c(new_tests, tests_cumulative))
# }

# fetch_from_zip <- function(dots) {

#   tests_cumulative <- NA
#   new_tests <- NA

#   tmpfile <- tempfile("country_data", fileext = ".zip")
#   tryCatch(
#     {
#       download.file(dots$data_url,
#         destfile = tmpfile, quiet = TRUE,
#       )
#     },
#     silent = FALSE,
#     condition = function(err) { }
#   )

#   if (file.size(tmpfile) > 0) {
#     file <- unzip(tmpfile)
#     data <- rio::import(file)
#     unlink(file)

#     if (dots$xpath_cumul == "nrow") {
#       tests_cumulative <- nrow(data)
#     }
#   }

#   return(c(new_tests, tests_cumulative))
# }

# fetch_from_selenium <- function(country, pattern) {
#   tests_cumulative <- NA
#   new_tests <- NA

#   today <- Sys.Date()
#   today_str <- as.character(today, format = "%Y%m%d")

#   country_to_grep <- country
#   if (country == "Cape Verde") {
#     country_to_grep <- "Cabo Verde"
#   } else if (country == "The Gambia") {
#     country_to_grep <- "Gambia"
#   } else if (country == "United Republic of Tanzania") {
#     country_to_grep <- "Tanzania"
#   }
#   line <- grep(paste0("echo: ", country_to_grep, ";"), readLines(paste0("output_selenium_", today_str, ".txt"), encoding = "UTF-8"), value = T)
#   message(line)
#   if (length(line) > 0) {
#     content <- gsub(paste0("echo: ", country_to_grep, ";"), "", line)
#     tests_cumulative <- as.numeric(gsub("[, .]", "", gsub(pattern, "\\1", str_extract(content, pattern))))
#   }

#   return(c(new_tests, tests_cumulative))
# }
