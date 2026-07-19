library(testthat)

test_that("frame-type derivation", {
  derive_frame <- function(threat, benefit) {
    if (is.na(threat) || is.na(benefit)) return(NA_character_)
    if (threat == "YES" && benefit == "YES") return("Both")
    if (threat == "YES" && benefit == "NO") return("Threat only")
    if (threat == "NO" && benefit == "YES") return("Benefit only")
    if (threat == "NO" && benefit == "NO") return("Neither")
    return(NA_character_)
  }
  
  expect_equal(derive_frame("NO", "NO"), "Neither")
  expect_equal(derive_frame("YES", "NO"), "Threat only")
  expect_equal(derive_frame("NO", "YES"), "Benefit only")
  expect_equal(derive_frame("YES", "YES"), "Both")
})
