
context("xmlparsedata")

test_that("empty input", {
  xml <- xml_parse_data(parse(text = "", keep.source = TRUE))
  expect_true(is.character(xml))
  expect_true(length(xml) == 1)
  expect_match(xml, "<exprlist>\\s*</exprlist>")
  expect_silent(x <- xml2::read_xml(xml))
})

test_that("trivial input", {
  xml <- xml_parse_data(parse(text = "# comment\n", keep.source = TRUE))
  expect_true(is.character(xml))
  expect_true(length(xml) == 1)
  expect_match(xml, "<exprlist>\\s*<COMMENT [^<]*</COMMENT>\\s*</exprlist>")
  expect_silent(x <- xml2::read_xml(xml))

  xml <- xml_parse_data(parse(text = "1", keep.source = TRUE))
  expect_match(
    xml,
    paste0(
      "<exprlist>\\s*<expr [^<]*<NUM_CONST.*</NUM_CONST>\\s*",
      "</expr>\\s*</exprlist>"
    )
  )
  expect_silent(x <- xml2::read_xml(xml))
})

test_that("non-trivial input", {
  ip <- deparse(utils::install.packages)
  xml <- xml_parse_data(parse(text = ip, keep.source = TRUE))
  expect_silent(x <- xml2::read_xml(xml))

  dp <- deparse(utils::install.packages)
  xml <- xml_parse_data(
    parse(text = dp, keep.source = TRUE),
    pretty = TRUE
  )
  expect_silent(x <- xml2::read_xml(xml))
})

test_that("UTF-8 is OK", {

  src <- "# comment with éápő"
  xml <- xml_parse_data(parse(text = src, keep.source = TRUE))
  x <- xml2::read_xml(xml)

  comment <- xml2::xml_children(x)
  col1 <- xml2::xml_attr(comment, "col1")
  col2 <- xml2::xml_attr(comment, "col2")

  expect_equal(
    substring(src, col1, col2),
    src
  )

  src <- "# 現行の学校文法では、英語にあるような「目的語」「補語」"
  xml <- xml_parse_data(parse(text = src, keep.source = TRUE))
  x <- xml2::read_xml(xml)

  comment <- xml2::xml_children(x)
  col1 <- xml2::xml_attr(comment, "col1")
  col2 <- xml2::xml_attr(comment, "col2")

  expect_equal(
    substring(src, col1, col2),
    iconv(src, to = "UTF-8")
  )

  src <- "`%ééé%` <- function(l, r) l + r"
  xml <- xml_parse_data(parse(text = src, keep.source = TRUE), pretty = TRUE)

  op <- xml2::xml_find_all(
    xml2::read_xml(xml),
    iconv("/exprlist/expr/expr/SYMBOL[text()='`%ééé%`']", to = "UTF-8")
  )
  expect_equal(length(op), 1)
})

test_that("data frame input", {

  p <- parse(text = "1 + 1", keep.source = TRUE)

  pd <- getParseData(p)
  attr(pd, "srcfile") <- NULL
  class(pd) <- "data.frame"
  x1 <- xml_parse_data(pd)

  x2 <- xml_parse_data(p)

  expect_equal(x1, x2)
})



test_that("Control-C character", {
  src <- "# Control-C \003
          # Bell  \007
          # Escape \027
          "
  xml <- xml_parse_data(parse(text = src, keep.source = TRUE))
  x <- xml2::read_xml(xml)
  expect_is(x, "xml_document")
})

