library(edgar)
library(XML)
library(stringr)

edgar_mda10q <- function (cik.no, filing.year) 
{
  f.type <- c("10-Q")
  if (!is.numeric(filing.year)) {
    cat("Please check the input year.")
    return()
  }
  output <- getFilings(cik.no = cik.no, form.type = f.type, 
                       filing.year, quarter = c(1, 2, 3, 4), downl.permit = "y")
  if (is.null(output)) {
    cat("No annual statements found for given CIK(s) and year(s).")
    return()
  }
  cat("Extracting 'Item 2' section...\n")
  progress.bar <- txtProgressBar(min = 0, max = nrow(output), 
                                 style = 3)
  CleanFiling2 <- function(text) {
    text <- gsub("[[:digit:]]+", "", text)
    text <- gsub("\\s{1,}", " ", text)
    text <- gsub("\"", "", text)
    return(text)
  }
  new.dir <- paste0("edgar_mda10q")
  dir.create(new.dir)
  output$extract.status <- 0
  output$company.name <- toupper(as.character(output$company.name))
  output$company.name <- gsub("\\s{2,}", " ", output$company.name)
  for (i in 1:nrow(output)) {
    f.type <- gsub("/", "", output$form.type[i])
    cname <- gsub("\\s{2,}", " ", output$company.name[i])
    year <- output$filing.year[i]
    cik <- output$cik[i]
    date.filed <- output$date.filed[i]
    accession.number <- output$accession.number[i]
    dest.filename <- paste0("edgar_Filings/Form ", f.type, 
                            "/", cik, "/", cik, "_", f.type, "_", date.filed, 
                            "_", accession.number, ".txt")
    filename2 <- paste0(new.dir, "/", cik, "_", f.type, 
                        "_", date.filed, "_", accession.number, ".txt")
    if (file.exists(filename2)) {
      output$extract.status[i] <- 1
      next
    }
    filing.text <- readLines(dest.filename)
    tryCatch({
      filing.text <- filing.text[(grep("<DOCUMENT>", filing.text, 
                                       ignore.case = TRUE)[1]):(grep("</DOCUMENT>", 
                                                                     filing.text, ignore.case = TRUE)[1])]
    }, error = function(e) {
      filing.text <- filing.text
    })
    if (any(grepl(pattern = "<xml>|<type>xml|<html>|10q.htm|<XBRL>", 
                  filing.text, ignore.case = T))) {
      doc <- XML::htmlParse(filing.text, asText = TRUE, 
                            useInternalNodes = TRUE, addFinalizer = FALSE)
      f.text <- XML::xpathSApply(doc, "//text()[not(ancestor::script)][not(ancestor::style)][not(ancestor::noscript)][not(ancestor::form)]", 
                                 XML::xmlValue)
      f.text <- iconv(f.text, "latin1", "ASCII", sub = " ")
    }
    else {
      f.text <- filing.text
    }
    f.text <- gsub("\\n|\\t|$", " ", f.text)
    f.text <- gsub("^\\s{1,}", "", f.text)
    f.text <- gsub(" s ", " ", f.text)
    empty.lnumbers <- grep("^\\s*$", f.text)
    if (length(empty.lnumbers) > 0) {
      f.text <- f.text[-empty.lnumbers]
    }
    if (f.type == "10-Q") {
      startline <- grep("^Item\\s{0,}2\\.{0,}[^A.|\\(A\\)]", 
                        f.text, ignore.case = TRUE)
      endline <- grep("^Item\\s{0,}2\\.{0,}(A|\\(A\\)|\\.A)", 
                      f.text, ignore.case = TRUE)
      if (length(endline) == 0 | (length(endline) != length(startline) & 
                                  !all(endline - startline >= 0))) {
        endline <- grep("^Item\\s{0,}3", f.text, ignore.case = TRUE)
      }
      if (length(startline) >= 2 && length(endline) >= 
          2) {
        startline <- startline[which.max(endline - startline)]
        endline <- endline[which.max(endline - startline)]
      }
    }
    else {
      startline <- grep("^Item\\s{0,}1", f.text, ignore.case = TRUE)
      endline <- grep("^Item\\s{0,}2", f.text, ignore.case = TRUE)
      if (length(endline) != length(startline) & !all(endline - 
                                                      startline >= 0)) {
        startline <- startline[which.max(endline - startline)]
        endline <- endline[which.max(endline - startline)]
      }
      if (length(startline) >= 2 && length(endline) >= 
          2) {
        startline <- startline[which.max(endline - startline)]
        endline <- endline[which.max(endline - startline)]
      }
    }
    md.dicusssion <- NA
    words.count <- 0
    if (length(startline) != 0 && length(endline) != 0) {
      startline <- startline[length(startline)]
      endline <- endline[length(endline)] - 1
      md.dicusssion <- paste(f.text[startline:endline], 
                             collapse = " ")
      md.dicusssion <- gsub("\\s{2,}", " ", md.dicusssion)
      words.count <- stringr::str_count(md.dicusssion, 
                                        pattern = "\\S+")
      header <- paste0("CIK: ", cik, "\n", "Company Name: ", 
                       cname, "\n", "Form Type : ", f.type, "\n", "Filing Date: ", 
                       date.filed, "\n", "Accession Number: ", accession.number)
      md.dicusssion <- paste0(header, "\n\n\n", md.dicusssion)
    }
    if ((!is.na(md.dicusssion)) & (words.count > 100)) {
      writeLines(md.dicusssion, filename2)
      output$extract.status[i] <- 1
    }
    setTxtProgressBar(progress.bar, i)
  }
  output$date.filed <- as.Date(as.character(output$date.filed), 
                               "%Y-%m-%d")
  close(progress.bar)
  output$quarter <- NULL
  output$filing.year <- NULL
  names(output)[names(output) == "status"] <- "downld.status"
  cat("MD&A section texts are stored in 'edgar_mda10q' directory.")
  return(output)
}
