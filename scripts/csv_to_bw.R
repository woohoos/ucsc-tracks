library(rtracklayer)
library(GenomicRanges)
library(GenomeInfoDb)

chrom_sizes <- read.table("hg38.chrom.sizes", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
chrom_info <- Seqinfo(seqnames = chrom_sizes$V1, seqlengths = chrom_sizes$V2)

# Handle overlapping regions
split_overlaps <- function(gr, chrom_info) {
  disjoint_ranges <- disjoin(gr)
  overlap_hits <- findOverlaps(gr, disjoint_ranges)
  
  new_scores <- tapply(gr$score[queryHits(overlap_hits)], subjectHits(overlap_hits), mean)
  
  new_gr <- GRanges(
    seqnames = seqnames(disjoint_ranges),
    ranges = ranges(disjoint_ranges),
    score = as.numeric(new_scores)
  )
  
  seqinfo(new_gr) <- chrom_info
  return(new_gr)
}

raw_files <- list.files("raw", recursive = TRUE, full.names = TRUE)

for (file in raw_files) {
  cat("Processing:", file, "\n")
  
  X <- read.csv(file, stringsAsFactors = FALSE)
  
  if ("strand" %in% colnames(X)) {
    X_plus <- subset(X, strand == "+")
    X_minus <- subset(X, strand == "-")
    
    # Process positive strand
    if (nrow(X_plus) > 0) {
      gr_plus <- GRanges(
        seqnames = X_plus$chr,
        ranges = IRanges(start = X_plus$start, end = X_plus$end),
        strand = "+",
        score = X_plus$score
      )
      
      common_chroms <- intersect(seqlevels(gr_plus), seqlevels(chrom_info))
      gr_plus <- keepSeqlevels(gr_plus, common_chroms, pruning.mode = "coarse")
      seqinfo(gr_plus) <- chrom_info[common_chroms]
      
      gr_plus <- split_overlaps(gr_plus, chrom_info)
      output_file <- gsub("^raw", "tracks", file)
      output_file <- sub("\\.[^.]+$", "_plus.bw", output_file)
      
      output_dir <- dirname(output_file)
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
      }
      
      export(gr_plus, output_file, format = "BigWig")
    }
    
    # Process negative strand
    if (nrow(X_minus) > 0) {
      gr_minus <- GRanges(
        seqnames = X_minus$chr,
        ranges = IRanges(start = X_minus$start, end = X_minus$end),
        strand = "-",
        score = X_minus$score
      )
      
      common_chroms <- intersect(seqlevels(gr_minus), seqlevels(chrom_info))
      gr_minus <- keepSeqlevels(gr_minus, common_chroms, pruning.mode = "coarse")
      seqinfo(gr_minus) <- chrom_info[common_chroms]
      
      gr_minus <- split_overlaps(gr_minus, chrom_info)
      output_file <- gsub("^raw", "tracks", file)
      output_file <- sub("\\.[^.]+$", "_minus.bw", output_file)
      
      output_dir <- dirname(output_file)
      if (!dir.exists(output_dir)) {
        dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
      }
      
      export(gr_minus, output_file, format = "BigWig")
    }
    
  } else {
    # Process as strandless
    gr_strandless <- GRanges(
      seqnames = X$chr,
      ranges = IRanges(start = X$start, end = X$end),
      score = X$score
    )
    
    common_chroms <- intersect(seqlevels(gr_strandless), seqlevels(chrom_info))
    gr_strandless <- keepSeqlevels(gr_strandless, common_chroms, pruning.mode = "coarse")
    seqinfo(gr_strandless) <- chrom_info[common_chroms]
    
    gr_strandless <- split_overlaps(gr_strandless, chrom_info)
    output_file <- gsub("^raw", "tracks", file)
    output_file <- sub("\\.[^.]+$", "_strandless.bw", output_file)
    
    output_dir <- dirname(output_file)
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    }
    
    export(gr_strandless, output_file, format = "BigWig")
  }
}