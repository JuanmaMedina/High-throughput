rm(list = ls())

## External packages ##
library(reshape2)
library(ggplot2)
library(gplots)
library(pheatmap)
library(dplyr)

# Data reading
setwd("~/HT/5. Data_mining/Cage_data_mining_exercise/")
df <- read.table("htbinf_cage_tpms.txt", h = T, stringsAsFactors = F)

# Re-name the columns
names(df) <- c("TSS_id", "location", "strand", "cerebellum", "embryos", 
               "liver", "lung", "macrophages", "somatocortex", "visual_cortex")

# Separate location into chromosome, start and end by pattern finding
myregex <- "(chr[0-9XM]*):([0-9]*)-([0-9]*)"

df$chromosome <- gsub(pattern = myregex, "\\1", x = df$location)
df$start <- as.numeric(gsub(pattern = myregex, "\\2", x = df$location))
df$end <- as.numeric(gsub(pattern = myregex, "\\3", x = df$location))

# Column reordering
df<- df[, c("TSS_id", "location", "chromosome", "start", "end", "cerebellum", 
            "embryos", "liver", "lung", "macrophages", "somatocortex", "visual_cortex")]

# TPM per tissue
tissues <- df[, c(6:12)]

# Scaled dataset (m = 0 and sd = 1 due to different library sizes across tissues)
scaled_tissues <- as.data.frame(scale(tissues))

# Re-size the dataset with mean = 10 to have positive values in the boxplots
scaled_tissues_10 <- scaled_tissues + 10

# Sanity check of the scaling process
colMeans(scaled_tissues_10)      # Mean = 10
apply(scaled_tissues_10, 2, sd)  # Sd = 1

# Merge scaled tissues with 5 first columns (ID, location and strand)
scaled_df <- cbind(df[, c(1:5)], scaled_tissues_10)


# Melting of the df (id.vars to keep those columns, the rest of them will be 
# associated with an ID, location and strand, with a TISSUE name and a TPM VALUE)
melted_scaled_df <- melt(data = scaled_df, id.vars = c("TSS_id", "location", "chromosome", 
                                                       "start", "end"), 
                         variable.name = "Tissue", value.name = "TPM_value")

# Boxplot of TPM values in each tissue
ggplot (data = melted_scaled_df) +
  geom_boxplot(aes(x = Tissue, y = TPM_value, fill = Tissue)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# All the values and their repetition number for each tissue (TABLE function),
# indicating types of TSS in terms of tissue-specific expression
TSS_per_tissue <- apply(tissues, 2, function(x) length(table(x)))

# Types of TSS in terms of tissue-specific expression (in all tissues)
TSS_all <- length(rapply(scaled_tissues_10, function(x) unique(x)))

# This way we obtain 124 different TSS in terms of expression intensity


# Similar tissues in terms of expression patterns: heatmaps and PCA

# Heatmaps # 
heatmap.2(as.matrix(tissues), trace = "none", col = redgreen)
pheatmap(as.matrix(tissues))

# PCA # 

# Define tissues names
tissue_names <- colnames(tissues)

# Dimensionality reduction transposing and scaling the data
pca_tissues <- prcomp(t(scaled_tissues), scale = T, center = T)

# Save data information and tissue names in a single DF
plot_tissues <- data.frame(pca_tissues$x, tissue_names)

# Proportion of variance extraction
prop_var <- summary(pca_tissues)$importance[2, ]

# PCA with the TSS differentiated by tissue
qplot(data = plot_tissues, x = PC1, y = PC2, color = tissue_names,
      geom = "text", label = tissue_names, show.legend = F) +
  labs(x = paste("PC1", round(prop_var[1] * 100, digits = 2), "%", sep = " "),
       y = paste("PC2", round(prop_var[2] * 100, digits = 2), "%", sep = " "))
      

# Applying a criteria of "> 13 TPM: tissue-specific TSS", the tissue-specific
# TSS IDs and locations are extracted as follows:
apply(scaled_tissues_10, 2, function(x) {x > 13}) %>%
  apply(2, function(x) scaled_df[x, c("location", "TSS_id")])

# Extracting the most expressed TSS in each tissue
best_TSS <- scaled_df[apply(scaled_tissues_10, 2, function (x) which.max(x)), 
                     c("location", "TSS_id")]

cbind(best_TSS, colnames(df)[6:12])


