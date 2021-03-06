get_status <- function(url) {
  return(data.frame(url = url, response_code = rvest::html_session(url) %>%
    httr::status_code()))
}

#' @importFrom stringr str_replace_all str_match
clean_selenium <- function(data) {

  data_clean <- data %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, ",", "")) %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, "\\.", "")) %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, " ", "")) %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, "’", "")) %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, "\\u202f", "")) %>%
    mutate(tests_cumulative = str_match(tests_cumulative, pattern = "\\d+")) %>%
    mutate(tests_cumulative = as.numeric(tests_cumulative)) %>%
    mutate(date = as.Date(date))

  return(data_clean)
}

#' @importFrom stringr str_replace_all str_match
clean_selenium_segregated <- function(data) {

  data_clean <- data %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, ",", "")) %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, "\\.", "")) %>%
    mutate(tests_cumulative = str_replace_all(tests_cumulative, " ", "")) %>%
    mutate(tests_cumulative = str_match(tests_cumulative, pattern = "\\d+")) %>%
    mutate(tests_cumulative = as.numeric(tests_cumulative)) %>%
    mutate(pcr_tests_cum = str_replace_all(pcr_tests_cum, ",", "")) %>%
    mutate(pcr_tests_cum = str_replace_all(pcr_tests_cum, "\\.", "")) %>%
    mutate(pcr_tests_cum = str_replace_all(pcr_tests_cum, " ", "")) %>%
    mutate(pcr_tests_cum = str_match(pcr_tests_cum, pattern = "\\d+")) %>%
    mutate(pcr_tests_cum = as.numeric(pcr_tests_cum)) %>%
    mutate(rapid_test_cum = str_replace_all(rapid_test_cum, ",", "")) %>%
    mutate(rapid_test_cum = str_replace_all(rapid_test_cum, "\\.", "")) %>%
    mutate(rapid_test_cum = str_replace_all(rapid_test_cum, " ", "")) %>%
    mutate(rapid_test_cum = str_match(rapid_test_cum, pattern = "\\d+")) %>%
    mutate(rapid_test_cum = as.numeric(rapid_test_cum)) %>%
    filter(!is.na(pcr_tests_cum) & !is.na(rapid_test_cum)) %>%
    mutate(date = as.Date(date))

  return(data_clean)
}

calculate_daily_tests_r_fetch <- function(data, tests_cumulative) {
  data_yesterday <- readr::read_csv(sprintf("https://raw.githubusercontent.com/dsbbfinddx/FINDCov19TrackerData/master/automated/fetch/%s-tests-R.csv", lubridate::today() - 1), quoted_na = FALSE) %>% # nolint
    dplyr::filter(country == data$country)

  # if no yesterday data exists yet, we return NA
  if (nrow(data_yesterday) == 0) {
    new_tests <- NA
    cli::cli_alert_warning("{.field {data$country}}: Yesterday's data not
      (yet) available.", wrap = TRUE)
    return(new_tests)
  } else {
    tests_yesterday <- as.numeric(data_yesterday$tests_cumulative)
    new_tests <- tests_cumulative - tests_yesterday
  }

  return(new_tests)
}

# written by Anna
#' @importFrom data.table data.table rbindlist
smooth_new_tests <- function(x, y) {
  # rle of NAs
  m <- rle(is.na(x))
  # if there is an NA add the number of times it shows up, if there is a value add 0
  no_of_NAs <- rep(ifelse(m$values, m$lengths, 0), times = m$lengths)

  # create a data table with variable, number of NAs and keep only the entries for values, with their original index in the data.frame
  dat <- data.table::data.table(x, y, no_of_NAs) %>%
    mutate(ind = as.numeric(rownames(.))) %>%
    filter(no_of_NAs == 0)
  # if there are value in the data.table for the variable
  if (nrow(dat) > 0) {

    dat_NA <- data.frame(index = 1:length(x), new_tests_smooth = NA)
    dat_ <- lapply(1:nrow(dat), function(i) {
      # for the first entry of dat, check if the original data frame has a value not in the first row, create a df with NA values up to the first value
      if (i == 1 & dat[i, ind] > 1) {
        ind_ <- dat[i, ind]
        rbind(
          data.frame(index = 1:(ind_ - 1), new_tests_smooth = NA),
          data.frame(index = ind_, new_tests_smooth = dat[i, x])
        )
        # for the first entry of dat, check if the original data frame has a value in the first row
      } else if (i == 1 & dat[i, ind] == 1) {
        ind_ <- dat[i, ind]
        data.frame(index = ind_, new_tests_smooth = dat[i, x])
      } else {
        # for the second entry and later check if there are values and if they come up in gaps or consecutively and
        # create the inbetween values using the diff betweeb the cumulative values reported
        ind_1 <- dat[i - 1, ind]
        ind_2 <- dat[i, ind]
        diff_ind <- ind_2 - ind_1
        if (diff_ind > 1) {
          cum_test <- dat[i - 1, y] + round(c(dat[i, x] * c(1:diff_ind) / diff_ind))
          smooth_test <- c(cum_test[1] - dat[i - 1, y], diff(cum_test))
          data.frame(index = (ind_1 + 1):ind_2, new_tests_smooth = smooth_test)
        } else {
          smooth_test <- dat[i, x]
          data.frame(index = ind_2, new_tests_smooth = smooth_test)
        }
      }
    })

    dat_ <- data.table::rbindlist(dat_) %>%
      full_join(dat_NA, by = "index") %>%
      select(index, new_tests_smooth.x) %>%
      rename(new_tests_smooth = new_tests_smooth.x)

  } else {
    dat_ <- data.frame(index = 1:length(x), new_tests_smooth = NA)
  }


  return(dat_$new_tests_smooth)

}

#' @importFrom data.table frollmean frollsum
robust_rollmean <- function(x) {
  ans <- data.table::frollmean(x, 7, na.rm = TRUE)
  no_of_obs <- data.table::frollsum(!is.na(x), 7, na.rm = T, fill = 0)
  ans[no_of_obs <= 3] <- NA
  ans
}

sum_basic <- function(x) {
  sum(x, na.rm = TRUE)
}

# Functions to calculate test_cumulative when new_test available
calc_cumulative_t <- function(cumulative_t, new_t) {
  for (i in 2:length(cumulative_t)) {
    if (!is.na(new_t[i]) & is.na(cumulative_t[i])) {
      cumulative_t[i] = cumulative_t[i-1] + new_t[i]
    }
  }
  cumulative_t
}

# Functions to calculate new_test when test_cumulative available
calc_new_t <- function(cumulative_t, new_t) {
  for (i in 2:length(cumulative_t)) {
    if (is.na(new_t[i]) & !is.na(cumulative_t[i])) {
      new_t[i] = cumulative_t[i] - cumulative_t[i-1]
    }
  }
  new_t
}

