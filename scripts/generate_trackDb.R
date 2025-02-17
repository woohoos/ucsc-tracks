github_user <- "woohoos"
repo_name <- "ucsc-tracks"
base_url <- paste0("https://raw.githubusercontent.com/", github_user, "/", repo_name, "/main/")

track_types <- list(
  ".bw" = "bigWig",
  ".bedGraph" = "bedGraph",
  ".bigBed" = "bigBed"
)

color_blue <- "0,0,255"         # methylation
color_red <- "255,0,0"          # pvalue/control
color_green <- "63,127,9"       # acetylation 
color_default <- "0,0,0"        

track_dirs <- list.dirs("tracks", recursive = FALSE)
track_db <- c()

for (folder in track_dirs) {
  folder_name <- basename(folder)
  super_track_name <- paste0("super_", folder_name)
  
  track_db <- c(track_db,
                paste0("track ", super_track_name),
                "superTrack on",
                "group custom",
                paste0("shortLabel ", folder_name, " Collection"),
                paste0("longLabel Group: ", folder_name),
                "visibility full",
                "aggregate transparentOverlay",  # Grouped auto-scaling
                "autoScale on",  # Scale based on visible tracks
                "maxHeightPixels 100:100:20",  # Height of the tracks
                ""
  )
  
  track_files <- list.files(folder, pattern = paste0("\\", names(track_types), collapse = "|"), full.names = FALSE)
  
  for (track in track_files) {
    ext <- tools::file_ext(track)
    track_type <- track_types[[paste0(".", ext)]]
    track_name <- sub(paste0(".", ext, "$"), "", track)
    
    track_path <- paste0(folder, "/", track)
    
    if (grepl("methylation|M", track, ignore.case = TRUE)) {
      track_color <- color_blue
    } else if (grepl("pvalue|control|kontrol|^M", track, ignore.case = TRUE)) {
      track_color <- color_red
    } else if (grepl("acetylation|^A", track, ignore.case = TRUE)) {
      track_color <- color_green
    } else {
      track_color <- color_default
    }
    
    track_db <- c(track_db,
                  paste0("track ", track_name),
                  paste0("parent ", super_track_name, " on"), 
                  paste0("bigDataUrl ", base_url, track_path),
                  paste0("type ", track_type),
                  paste0("shortLabel ", track_name),
                  paste0("longLabel ", track_name, " (", folder_name, ")"),
                  paste0("color ", track_color),
                  "visibility full",
                  ""
    )
  }
}

writeLines(track_db, "trackDb.txt")
cat("UCSC updated!\n")
