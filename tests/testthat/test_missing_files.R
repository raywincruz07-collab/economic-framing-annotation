test_that("No missing files", {
  expect_true(file.exists(file.path("../../", "data")))
})
