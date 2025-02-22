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
                "maxHeightPixels 100:50:20",  # Height of the tracks
                ""
  )
  
  track_files <- list.files(folder, pattern = paste0("\\", names(track_types), collapse = "|"), full.names = FALSE)
  
  for (track in track_files) {
    ext <- tools::file_ext(track)
    track_type <- track_types[[paste0(".", ext)]]
    track_name <- sub(paste0(".", ext, "$"), "", track)
    
    track_path <- paste0(folder, "/", track)
    
    if (grepl("methylation|BW_M", track, ignore.case = TRUE)) {
      track_color <- color_blue
    } else if (grepl("pvalue|control|kontrol|^BW_K", track, ignore.case = TRUE)) {
      track_color <- color_red
    } else if (grepl("acetylation|^BW_A", track, ignore.case = TRUE)) {
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



# MultiWig Track Configuration to Append at the End
multiWig_config <- c(
  "track multiWig1",
  "type bigWig",
  "container multiWig",
  "shortLabel Ex. multiWig container",
  "longLabel This multiWig overlay track graphs points from three bigWig files.",
  "visibility full",
  "aggregate transparentOverlay",
  "showSubtrackColorOnUi on",
  "maxHeightPixels 500:100:8",
  "viewLimits 1:20",
  "priority 1",
  "html examplePage",
  "",
  "    track wig1",
  "    bigDataUrl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeCshlLongRnaSeq/wgEncodeCshlLongRnaSeqA549CellLongnonpolyaMinusRawSigRep1.bigWig",
  "    shortLabel Overlay bigWig1",
  "    longLabel This is an example bigWig1 displaying Raw Signal from the ENCODE RNA-seq CSHL track, graphing just points as default.",
  "    parent multiWig1",
  "    graphTypeDefault points",
  "    type bigWig",
  "    color 255,0,0",
  "",
  "    track wig2",
  "    bigDataUrl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeCshlLongRnaSeq/wgEncodeCshlLongRnaSeqA549CellLongnonpolyaPlusRawSigRep1.bigWig",
  "    shortLabel Overlay bigWig2",
  "    longLabel This is an example bigWig2 displaying Raw Signal from the ENCODE RNA-seq CSHL track, graphing just points as default.",
  "    graphTypeDefault points",
  "    parent multiWig1",
  "    type bigWig",
  "    color 0,255,0",
  "",
  "    track wig3",
  "    bigDataUrl http://hgdownload.soe.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeCshlLongRnaSeq/wgEncodeCshlLongRnaSeqAg04450CellLongnonpolyaPlusRawSigRep1.bigWig",
  "    shortLabel Overlay bigWig3",
  "    longLabel This is an example bigWig3 displaying Raw Signal from the ENCODE RNA-seq CSHL track, graphing just points as default.",
  "    graphTypeDefault points",
  "    parent multiWig1",
  "    type bigWig",
  "    color 95,158,160",
  ""
)

# Combine existing tracks and multiWig config
track_db <- c(track_db, multiWig_config)

# Write to trackDb.txt
writeLines(track_db, "trackDb.txt")

cat("✅ UCSC trackDb.txt updated with multiWig track!\n")


