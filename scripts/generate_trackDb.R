github_user <- "woohoos"
repo_name <- "ucsc-tracks"
base_url <- paste0("https://raw.githubusercontent.com/", github_user, "/", repo_name, "/main/")

track_types <- list(
  ".bw" = "bigWig",
  ".bedGraph" = "bedGraph",
  ".bigBed" = "bigBed"
)

color_plus <- "0,0,255"         # Blue for Plus strand
color_minus <- "255,0,0"        # Red for Minus strand
color_strandless <- "0,128,0"   # Green for Strandless
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
                "aggregate transparentOverlay",
                "autoScale on",
                "maxHeightPixels 100:50:20",
                ""
  )
  
  track_files <- list.files(folder, pattern = "\\.bw$", full.names = FALSE)
  
  # Check if the folder starts with "seq_"
  if (grepl("^seq_", folder_name)) {
    # Separate plus, minus, and strandless files
    plus_files <- grep("_plus\\.bw$", track_files, value = TRUE)
    minus_files <- grep("_minus\\.bw$", track_files, value = TRUE)
    strandless_files <- grep("_strandless\\.bw$", track_files, value = TRUE)
    
    # Process strand-specific tracks into a single multiWig container
    if (length(plus_files) > 0 && length(minus_files) > 0) {
      multiwig_name <- paste0("multiwig_", folder_name)
      
      track_db <- c(track_db,
                    paste0("track ", multiwig_name),
                    "type bigWig",
                    "container multiWig",
                    paste0("shortLabel ", folder_name, " RNA-seq"),
                    paste0("longLabel RNA-seq (Strand-Specific) - ", folder_name),
                    "visibility full",
                    "aggregate transparentOverlay",
                    "showSubtrackColorOnUi on",
                    "maxHeightPixels 500:100:8",
                    "viewLimits 1:20",
                    "priority 1",
                    ""
      )
      
      # Add plus strand to the multiWig track
      for (track in plus_files) {
        track_name <- sub("\\.bw$", "", track)
        track_db <- c(track_db,
                      paste0("    track ", track_name),
                      paste0("    parent ", multiwig_name),
                      paste0("    bigDataUrl ", base_url, folder, "/", track),
                      paste0("    shortLabel ", track_name),
                      paste0("    longLabel RNA-seq Plus Strand - ", folder_name),
                      "    graphTypeDefault points",
                      "    type bigWig",
                      paste0("    color ", color_plus),
                      ""
        )
      }
      
      # Add minus strand to the multiWig track
      for (track in minus_files) {
        track_name <- sub("\\.bw$", "", track)
        track_db <- c(track_db,
                      paste0("    track ", track_name),
                      paste0("    parent ", multiwig_name),
                      paste0("    bigDataUrl ", base_url, folder, "/", track),
                      paste0("    shortLabel ", track_name),
                      paste0("    longLabel RNA-seq Minus Strand - ", folder_name),
                      "    graphTypeDefault points",
                      "    type bigWig",
                      paste0("    color ", color_minus),
                      ""
        )
      }
    }
    
    # Process strandless tracks separately
    for (track in strandless_files) {
      track_name <- sub("\\.bw$", "", track)
      track_db <- c(track_db,
                    paste0("track ", track_name),
                    paste0("parent ", super_track_name, " on"), 
                    paste0("bigDataUrl ", base_url, folder, "/", track),
                    "type bigWig",
                    paste0("shortLabel ", track_name),
                    paste0("longLabel RNA-seq Strandless - ", folder_name),
                    paste0("color ", color_strandless),
                    "visibility full",
                    ""
      )
    }
    
  } else {
    # Default behavior for all other directories
    for (track in track_files) {
      ext <- tools::file_ext(track)
      track_type <- track_types[[paste0(".", ext)]]
      track_name <- sub(paste0(".", ext, "$"), "", track)
      track_path <- paste0(folder, "/", track)
      
      # Assign colors based on track name
      if (grepl("methylation|BW_M", track, ignore.case = TRUE)) {
        track_color <- color_plus
      } else if (grepl("pvalue|control|kontrol|^BW_K", track, ignore.case = TRUE)) {
        track_color <- color_minus
      } else if (grepl("acetylation|^BW_A", track, ignore.case = TRUE)) {
        track_color <- color_strandless
      } else {
        track_color <- color_default
      }
      
      # Add track entry
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
}

writeLines(track_db, "trackDb.txt")
