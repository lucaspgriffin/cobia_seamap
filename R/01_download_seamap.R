# Download the SEAMAP plankton survey data.
#
# Source: Gulf States Marine Fisheries Commission, https://seamapdata.gsmfc.org/
# The "Plankton Survey Data (CSV)" link gives one zip of the whole archive. It is a few hundred MB
# and is re-released periodically, so the release date is recorded alongside it.
#
# Tables used here:
#   STAREC   one row per station: date, time, position, depth, gears deployed
#   ISTRWK   one row per plankton sample: gear, mesh, volume filtered, whether it was sorted
#   ISARWK   one row per taxon per sample: counts, aliquot
#   ILFRWK   one row per measured larva: length
#
# Run once. Later scripts read from data/raw/seamap/.

source("R/00_setup.R")

URL <- "https://seamapdata.gsmfc.org/files/SEAMAPPlanktonCSV.zip"
zipfile <- file.path(dir_raw, "SEAMAPPlanktonCSV.zip")
want <- c("STAREC.csv", "ISTRWK.csv", "ISARWK.csv", "ILFRWK.csv")

if (!file.exists(zipfile)) {
  message("downloading ", URL)
  options(timeout = 3600)
  download.file(URL, zipfile, mode = "wb")
}

have <- file.exists(file.path(dir_seamap, want))
if (!all(have)) {
  inside <- unzip(zipfile, list = TRUE)$Name
  for (f in want[!have]) {
    hit <- inside[basename(inside) == f]
    if (!length(hit)) stop("not in the zip: ", f)
    unzip(zipfile, files = hit[1], exdir = dir_seamap, junkpaths = TRUE)
  }
}

writeLines(c(paste("source:", URL),
             paste("downloaded:", format(Sys.time(), "%Y-%m-%d %H:%M %Z")),
             paste("zip mtime:", format(file.mtime(zipfile)))),
           file.path(dir_seamap, "SOURCE.txt"))

for (f in want) {
  n <- length(count.fields(file.path(dir_seamap, f), sep = ",", quote = "\"")) - 1
  message(sprintf("%-12s %9s rows", f, format(n, big.mark = ",")))
}
