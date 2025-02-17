github_user <- "woohoos"
repo_name <- "ucsc-tracks"

base_url <- paste0("https://raw.githubusercontent.com/", github_user, "/", repo_name, "/main/tracks/")

track_types <- list(
  ".bw" = "bigWig",
  ".bedGraph" = "bedGraph",
  ".bigBed" = "bigBed"
)

track_files <- list.files("tracks", pattern = paste0("\\", names(track_types), collapse = "|"), full.names = FALSE)

track_db <- c()
for (track in track_files) {
  ext <- tools::file_ext(track)
  track_type <- track_types[[paste0(".", ext)]]
  track_name <- sub(paste0(".", ext, "$"), "", track)
  
  track_db <- c(track_db,
                paste0("track ", track_name),
                paste0("bigDataUrl ", base_url, track),
                paste0("type ", track_type),
                paste0("shortLabel ", track_name),
                paste0("longLabel ", track_name, " data"),
                "visibility full",
                ""
  )
}

writeLines(track_db, "trackDb.txt")

cat("rackDb.txt updated!!!\n")
