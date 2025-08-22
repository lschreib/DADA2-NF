#' Sanger Sequencing De Novo Basecalling Workflow
#'
#' This script is a work in progress to provide R-based basecalling of Sanger sequencing trace data.
#' It's inpsired by the work of Mohammed et al. 2013 ("Novel algorithms for accurate DNA base-calling"; doi:10.4236/jbise.2013.62020)
#' In summary it will perform the following steps:
#' 1. **Color correction of chromatograms based on a mixing matrix
#' 2. **Peak sharpening using iterative deconvolution with a Gaussian point spread function (PSF)
#' 3. **Feature extraction (identification of feature coordinates using the first derivative -> max within coordinates = location)
#' 4. **Consolidation of feature coordinates across channels
#' 5. **Simple basecalling for each window based on the maximum signal intensity across the channels
#' 6. **Assignment of quality values to called bases by mimicking KB-based quality values and based on original (raw) trace data
#'
#' **Functions:**
#' - `extract_peaks(coord_list, trace)`: Extracts trace segments defined by coordinate ranges.
#' - `make_peak_df(peaks, channel_name)`: Converts peak lists to data frames for plotting.
#' - `normalize_peaks(peak_list)`: Normalizes each peak to its maximum intensity.
#' - `center_peaks(peak_list)`: Centers each peak within a vector for averaging.
#' - `average_peaks(peak_list)`: Computes the average peak from a list of centered peaks.
#' - `fit_gaussian(peak)`: Fits a Gaussian curve to the averaged peak.
#' - `calc_ratio_matrix(trace_matrix)`: Calculates signal ratios for each channel.
#' - `find_max_ratios(ratio_vector, percentile)`: Identifies indices above a percentile threshold.
#' - `find_clear_peaks(ratio_matrix, percentile)`: Finds clear peak positions across all channels.
#' - `calculate_mixing_matrix(peaks_matrix)`: Computes the mixing matrix for color correction.
#' - `color_correction(trace_matrix, peaks_matrix)`: Applies color correction using the mixing matrix.
#' - `iterative_deconvolution(input_trace, h, lambda, max_iter, tol)`: Performs iterative deconvolution for peak sharpening.
#' - `deconvolute_traces(trace_matrix, h, lambda, max_iter)`: Applies deconvolution to all channels.
#'
#' **Dependencies:** 
#' - `sangerseqR`, `ggplot2`, `reshape2`, `cowplot`
#'
#' **Usage:** 
#' - Update the file path to your AB1 trace file.
#' - Run the script to process and visualize Sanger sequencing traces.
#'
#' **Note:** 
#' - Peak coordinates are hard-coded and should be adapted for different datasets.
#' - The workflow is designed for research and prototyping purposes.
library("sangerseqR")
# library("sangeranalyseR") # Not needed so far
library("ggplot2")
library("reshape2")
library("cowplot")

# Don't change!!! Our reference for this fit will be a hard-coded trace200
test_data <- readsangerseq("/Users/lschreib/Documents/Projects/SangerSequences/dedup/trace200.ab1")

# Plot the A-channel
trace_df <- melt(test_data@traceMatrix)
colnames(trace_df) <- c("position", "channel", "intensity")

head(trace_df)


ggplot() +
    geom_line(
        data = trace_df[trace_df$channel == "1" & trace_df$position > 100 & trace_df$position < 1000, ],
        mapping = aes(x = position, y = intensity),
        color = "black"
    ) +
    scale_x_continuous(breaks = seq(2000, 3000, by = 10)) +
    labs(title = "B-channel Trace", x = "Position", y = "Intensity") +
    theme(axis.text.x = element_text(angle = 90, hjust = 1, size = 7))

# Functions
extract_peaks <- function(coord_list, trace) {
    peaks <- list()
    for (i in 1:length(coord_list)) {
        peaks[[i]] <- trace[coord_list[[i]][1]:coord_list[[i]][2]]
    }
    return(peaks)
}

# Channel 1 peaks
a_channel_peaks <- list()
a_channel_peaks[[1]] <- c(220, 260)
a_channel_peaks[[2]] <- c(260, 295)
a_channel_peaks[[3]] <- c(600, 640)
a_channel_peaks[[4]] <- c(2330, 2370)
a_channel_peaks[[5]] <- c(2760, 2790)
a_channel_peaks[[6]] <- c(3020, 3060)
a_channel_peaks[[7]] <- c(3080, 3115)
a_channel_peaks[[8]] <- c(3400, 3440)
a_channel_peaks[[9]] <- c(3460, 3495)
a_channel_peaks[[10]] <- c(3920, 3950)

a_peaks <- extract_peaks(a_channel_peaks, test_data@traceMatrix[, 1])

# Channel 2 peaks
c_channel_peaks <- list()
c_channel_peaks[[1]] <- c(210, 260)
c_channel_peaks[[2]] <- c(500, 550)
c_channel_peaks[[3]] <- c(680, 720)
c_channel_peaks[[4]] <- c(890, 920)
c_channel_peaks[[5]] <- c(950, 990)
c_channel_peaks[[6]] <- c(1130, 1170)
c_channel_peaks[[7]] <- c(1170, 1200)
c_channel_peaks[[8]] <- c(1315, 1350)
c_channel_peaks[[9]] <- c(1500, 1540)
c_channel_peaks[[10]] <- c(1660, 1700)

c_peaks <- extract_peaks(c_channel_peaks, test_data@traceMatrix[, 2])


# Channel 3 peaks
g_channel_peaks <- list()
g_channel_peaks[[1]] <- c(280, 320)
g_channel_peaks[[2]] <- c(410, 440)
g_channel_peaks[[3]] <- c(520, 550)
g_channel_peaks[[4]] <- c(2270, 2310)
g_channel_peaks[[5]] <- c(2730, 2770)
g_channel_peaks[[6]] <- c(3650, 3690)
g_channel_peaks[[7]] <- c(470, 500)
g_channel_peaks[[8]] <- c(625, 650)
g_channel_peaks[[9]] <- c(650, 675)

g_channel_peaks[[10]] <- c(770, 795)

g_peaks <- extract_peaks(g_channel_peaks, test_data@traceMatrix[, 3])

# Channel 4 peaks
t_channel_peaks <- list()
t_channel_peaks[[1]] <- c(250, 290)
t_channel_peaks[[2]] <- c(305, 340)
t_channel_peaks[[3]] <- c(370, 405)
t_channel_peaks[[4]] <- c(460, 490)
t_channel_peaks[[5]] <- c(1890, 1920)
t_channel_peaks[[6]] <- c(1950, 1980)
t_channel_peaks[[7]] <- c(2000, 2040)
t_channel_peaks[[8]] <- c(2080, 2105)
t_channel_peaks[[9]] <- c(2105, 2130)
t_channel_peaks[[10]] <- c(2635, 2670)

t_peaks <- extract_peaks(t_channel_peaks, test_data@traceMatrix[, 4])




make_peak_df <- function(peaks, channel_name) {
    do.call(rbind, lapply(seq_along(peaks), function(i) {
        data.frame(
            position = 1:length(peaks[[i]]),
            intensity = peaks[[i]],
            channel = channel_name,
            peak = i
        )
    }))
}

a_df <- make_peak_df(a_peaks, "A")
c_df <- make_peak_df(c_peaks, "C")
g_df <- make_peak_df(g_peaks, "G")
t_df <- make_peak_df(t_peaks, "T")
peaks_df <- rbind(a_df, c_df, g_df, t_df)

ggplot(peaks_df, aes(x = position, y = intensity, color = channel, group = interaction(channel, peak))) +
    geom_line() +
    labs(title = "Extracted Peaks", x = "Position", y = "Intensity") +
    theme_minimal()

# Combine peak lists
peak_list <- c(a_peaks, c_peaks, g_peaks, t_peaks)

# Looks very good
normalize_peaks <- function(peak_list) {
    normalized_peaks <- list()
    for (i in seq_along(peak_list)) {
        normalized_peaks[[i]] <- peak_list[[i]] / max(peak_list[[i]])
    }
    return(normalized_peaks)
}

normalized_peaks <- normalize_peaks(peak_list = peak_list)

normalize_peaks_df <- make_peak_df(normalized_peaks, "Normalized")

ggplot(normalize_peaks_df, aes(x = position, y = intensity, color = channel, group = interaction(channel, peak))) +
    geom_line() +
    labs(title = "Normalized Peaks", x = "Position", y = "Intensity") +
    theme_minimal()


center_peaks <- function(peak_list) {
    # Cycle through peak list to find the maximum length of any trace section
    element_lengths <- sapply(peak_list, length)
    max_length <- max(element_lengths)
    # The center point will be the middle of the new length
    center_point <- (max_length + 1)
    # Add buffer space to the length to have enough room to position the peaks correctly
    full_length <- max_length + 1 + max_length
    # Create a new list to hold the centered peaks
    centered_peaks <- vector("list", length(peak_list))
    for (i in seq_along(peak_list)) {
        # Create a new vector of NAs with the maximum length
        new_vector <- rep(0, full_length)
        # Get the current peak's maximum intensity
        center_of_peak <- which.max(peak_list[[i]])
        new_vector_start <- center_point - center_of_peak
        new_vector_end <- center_point - center_of_peak + length(peak_list[[i]]) - 1
        # Center the peak by placing it in the middle of the new vector
        new_vector[new_vector_start:new_vector_end] <- peak_list[[i]]
        # Add the centered peak to the new list
        centered_peaks[[i]] <- new_vector
    }
    return(centered_peaks)
}

centered_peaks <- center_peaks(normalized_peaks)

center_peaks_df <- make_peak_df(centered_peaks, "Centered")

ggplot(center_peaks_df, aes(x = position, y = intensity, color = channel, group = interaction(channel, peak))) +
    geom_line() +
    labs(title = "Centered Peaks", x = "Position", y = "Intensity") +
    theme_minimal()

average_peaks <- function(peak_list) {
    combined_peaks_matrix <- do.call(rbind, peak_list)
    averaged_peak <- colMeans(combined_peaks_matrix, na.rm = TRUE)
    return(averaged_peak)
}

averaged_peak <- average_peaks(centered_peaks)

# Re-normalize the averaged peak
normalized_averaged_peak <- averaged_peak / max(averaged_peak)

average_peak_df <- make_peak_df(list(normalized_averaged_peak), "Averaged")

ggplot(average_peak_df, aes(x = position, y = intensity, color = channel, group = interaction(channel, peak))) +
    geom_line() +
    labs(title = "Averaged Peaks", x = "Position", y = "Intensity") +
    theme_minimal()

# Fit a Gaussian to the averaged peak
fit_gaussian <- function(peak) {
    # Define the Gaussian function
    gaussian <- function(x, mean, sd, amplitude) {
        amplitude * exp(-((x - mean)^2) / (2 * sd^2))
    }

    # Initial parameter estimates
    initial_params <- list(mean = which.max(peak), sd = 1, amplitude = max(peak))

    # Fit the Gaussian model
    fit <- nls(peak ~ gaussian(1:length(peak), mean, sd, amplitude), data = data.frame(peak), start = initial_params)

    return(fit)
}

gaussian_fit <- fit_gaussian(normalized_averaged_peak)

# Generate a Gaussian Point Spread Function (PSF) from the fitted data
params <- coef(gaussian_fit)
mean_val <- params["mean"]
sd_val <- params["sd"]

x_vals <- seq(1, length(normalized_averaged_peak))
psf <- dnorm(x_vals, mean = mean_val, sd = sd_val)
plot(1:length(psf), psf, type = "l", main = "Gaussian Point Spread Function (dnorm)", xlab = "Position", ylab = "Density")

# Threshold the PSF to reduce noise
psf[psf < 0.0001] <- 0
# Clip trailing zeros
nonzero_idx <- which(psf != 0)
psf_clipped <- psf[min(nonzero_idx):max(nonzero_idx)]
psf_clipped <- psf_clipped / sum(psf_clipped) # Re-normalize

psf_clipped <- psf_clipped / sum(psf_clipped) # Re-normalize to sum 1

plot(1:length(psf_clipped), psf_clipped, type = "l", main = "Gaussian Point Spread Function (dnorm)", xlab = "Position", ylab = "Density")

# For deconvolution the PSF should be slightly (10%-30%) wider than what was determined empirically
# -> increase sd by 10%-30% and test the effects on the deconvolution results
psf <- dnorm(x_vals, mean = mean_val, sd = 1.2 * sd_val)
plot(1:length(psf), psf, type = "l", main = "Gaussian Point Spread Function (dnorm)", xlab = "Position", ylab = "Density")




#################################
# Combine with whole workflow
#################################
trace_matrix <- test_data@traceMatrix

colnames(trace_matrix) <- c("A", "C", "G", "T")


# identify_peak_regions <- function(trace_matrix, percentile = 0.1){
calc_ratio_matrix <- function(trace_matrix) {
    ratio_matrix <- matrix(nrow = nrow(trace_matrix), ncol = 4)
    for (i in 1:nrow(trace_matrix)) {
        denom1 <- trace_matrix[i, 2] + trace_matrix[i, 3] + trace_matrix[i, 4]
        denom2 <- trace_matrix[i, 1] + trace_matrix[i, 3] + trace_matrix[i, 4]
        denom3 <- trace_matrix[i, 2] + trace_matrix[i, 1] + trace_matrix[i, 4]
        denom4 <- trace_matrix[i, 1] + trace_matrix[i, 2] + trace_matrix[i, 3]

        ratio_matrix[i, 1] <- ifelse(denom1 == 0, NA, trace_matrix[i, 1] / denom1)
        ratio_matrix[i, 2] <- ifelse(denom2 == 0, NA, trace_matrix[i, 2] / denom2)
        ratio_matrix[i, 3] <- ifelse(denom3 == 0, NA, trace_matrix[i, 3] / denom3)
        ratio_matrix[i, 4] <- ifelse(denom4 == 0, NA, trace_matrix[i, 4] / denom4)
    }
    return(ratio_matrix)
}


find_max_ratios <- function(ratio_vector, percentile = 0.1) {
    # Calculate the threshold value for the given percentile
    threshold <- quantile(ratio_vector, probs = 1 - percentile, na.rm = TRUE)

    # Find the indices of values greater than or equal to the threshold
    indices <- which(ratio_vector >= threshold & !is.na(ratio_vector))

    return(indices)
}

find_clear_peaks <- function(ratio_matrix, percentile = 0.1) {
    # A channel
    a_channel_indices <- find_max_ratios(ratio_matrix[, 1], percentile = percentile)
    # C channel
    c_channel_indices <- find_max_ratios(ratio_matrix[, 2], percentile = percentile)
    # G channel
    g_channel_indices <- find_max_ratios(ratio_matrix[, 3], percentile = percentile)
    # T channel
    t_channel_indices <- find_max_ratios(ratio_matrix[, 4], percentile = percentile)

    index_list <- unique(c(a_channel_indices, c_channel_indices, g_channel_indices, t_channel_indices))

    return(index_list)
}


ratio_matrix <- calc_ratio_matrix(trace_matrix = trace_matrix)
peaks_matrix <- trace_matrix[find_clear_peaks(ratio_matrix = ratio_matrix, percentile = 0.1), ]


calculate_mixing_matrix <- function(peaks_matrix) {
    peaks_matrix <- scale(peaks_matrix)
    mixing_matrix <- cor(peaks_matrix)
    return(mixing_matrix)
}

color_correction <- function(trace_matrix, peaks_matrix) {
    M <- calculate_mixing_matrix(peaks_matrix) # Calculate mixing matrix
    trace_matrix_cc <- t(M %*% t(trace_matrix)) # Perform color correction
    # Clip negative values in the corrected signals
    # After color correction, negative signal values are not physically meaningful and may arise due to matrix operations.
    # Therefore, we set any negative values to zero to ensure all corrected signals remain valid.
    trace_matrix_cc[trace_matrix_cc < 0] <- 0 # Set negative corrected signals to zero
    return(trace_matrix_cc)
}

# Apply the mixing matrix to the raw signal matrix
trace_matrix_cc <- color_correction(trace_matrix = trace_matrix, peaks_matrix = peaks_matrix) # Perform color correction

# Plot before and after

# Convert the original trace matrix to a data frame
trace_matrix_df <- as.data.frame(trace_matrix)
trace_matrix_df$Position <- 1:nrow(trace_matrix) # Add a position column
trace_matrix_long <- reshape2::melt(trace_matrix_df, id.vars = "Position", variable.name = "Channel", value.name = "Intensity")

# Convert the corrected trace matrix to a data frame
trace_matrix_cc_df <- as.data.frame(trace_matrix_cc)
trace_matrix_cc_df$Position <- 1:nrow(trace_matrix_cc) # Add a position column
trace_matrix_cc_long <- reshape2::melt(trace_matrix_cc_df, id.vars = "Position", variable.name = "Channel", value.name = "Intensity")

# Plot the original trace matrix
p1 <- ggplot(trace_matrix_long[trace_matrix_long$Position > 500 &
    trace_matrix_long$Position < 1500, ], aes(x = Position, y = Intensity, color = Channel)) +
    geom_line() +
    labs(title = "Original Trace Matrix", x = "Position", y = "Intensity") +
    theme_minimal()

# Plot the corrected trace matrix
p2 <- ggplot(trace_matrix_cc_long[trace_matrix_cc_long$Position > 500 &
    trace_matrix_cc_long$Position < 1500, ], aes(x = Position, y = Intensity, color = Channel)) +
    geom_line() +
    labs(title = "Corrected Trace Matrix", x = "Position", y = "Intensity") +
    ylim(c(0, max(trace_matrix_long$Intensity))) +
    theme_minimal()

# Print the plots
plot_grid(p1, p2, ncol = 1)



#######################################
# Peak sharpening
#######################################

# During this step we iteratively convolute the traces and a
# Gaussian point spread function (a Gauss curve) to sharpen the peaks

# Function to perform iterative deconvolution
iterative_deconvolution <- function(input_trace, h, lambda = 0.1, max_iter = 60, tol = 0.0000001) {
    # Normalize the input trace
    input_trace_norm <- input_trace / max(input_trace)

    # Initialize the deconvolved signal
    input_trace_deconv <- input_trace_norm

    # Perform iterative deconvolution
    for (y in 1:max_iter) {
        print(paste0(c("Running iteration", y, "of", max_iter)))
        # Convolve the current deconvolved signal with the point spread function
        h_conv_itd <- convolve(input_trace_deconv, rev(h), type = "open")

        # Update the deconvolved signal
        input_trace_deconv_new <- input_trace_deconv + lambda * (input_trace_norm - h_conv_itd[1:length(input_trace_deconv)])

        # Clip negative values
        input_trace_deconv_new[input_trace_deconv_new < 0] <- 0

        # print(paste0(c("After iteration", y, "of", max_iter, " the difference is: ", max(abs(input_trace_deconv_new - input_trace_deconv)))))
        # Check for convergence
        if (max(abs(input_trace_deconv_new - input_trace_deconv)) < tol) {
            print(paste0(c("Converged after", y, "iterations")))
            break
        }

        # Update the signal for the next iteration
        input_trace_deconv <- input_trace_deconv_new
    }
    # Re-scale vector
    input_trace_deconv <- (input_trace_deconv / max(input_trace_deconv)) * max(input_trace)

    return(input_trace_deconv)
}

# Generate a Gaussian Point Spread Function (PSF) from the fitted data
params <- coef(gaussian_fit)
mean_val <- params["mean"]
sd_val <- params["sd"]

x_vals <- seq(1, length(normalized_averaged_peak))
psf <- dnorm(x_vals, mean = mean_val, sd = sd_val * 0.5)

# Thresholding the PSF to reduce noise
psf[psf < 0.0001] <- 0
# Clip trailing zeros
nonzero_idx <- which(psf != 0)
psf_clipped <- psf[min(nonzero_idx):max(nonzero_idx)]
psf_clipped <- psf_clipped / sum(psf_clipped) # Re-normalize

psf_clipped <- psf_clipped / sum(psf_clipped) # Re-normalize to sum 1

plot(1:length(psf_clipped), psf_clipped, type = "l", main = "Gaussian Point Spread Function (Clipped)", xlab = "Position", ylab = "Density")



deconvolute_traces <- function(trace_matrix, h, lambda, max_iter) {
    deconv_matrix <- matrix(nrow = nrow(trace_matrix), ncol = 4)
    colnames(deconv_matrix) <- c("A", "C", "G", "T")
    # Deconvolution
    deconv_matrix[, 1] <- iterative_deconvolution(trace_matrix[, 1], h = h, lambda = lambda, max_iter = max_iter) # A channel
    deconv_matrix[, 2] <- iterative_deconvolution(trace_matrix[, 2], h = h, lambda = lambda, max_iter = max_iter) # C channel
    deconv_matrix[, 3] <- iterative_deconvolution(trace_matrix[, 3], h = h, lambda = lambda, max_iter = max_iter) # G channel
    deconv_matrix[, 4] <- iterative_deconvolution(trace_matrix[, 4], h = h, lambda = lambda, max_iter = max_iter) # T channel
    return(deconv_matrix)
}

deconv_matrix <- deconvolute_traces(trace_matrix = trace_matrix_cc, h = psf_clipped, lambda = 0.05, max_it = 50)
# Clip small values
deconv_matrix[deconv_matrix < 0.1] <- 0


# Plot before and after

# Convert the original trace matrix to a data frame
trace_matrix_df <- as.data.frame(trace_matrix)
trace_matrix_df$Position <- 1:nrow(trace_matrix) # Add a position column
trace_matrix_long <- reshape2::melt(trace_matrix_df, id.vars = "Position", variable.name = "Channel", value.name = "Intensity")

# Convert the corrected trace matrix to a data frame
trace_matrix_cc_df <- as.data.frame(trace_matrix_cc)
trace_matrix_cc_df$Position <- 1:nrow(trace_matrix_cc) # Add a position column
trace_matrix_cc_long <- reshape2::melt(trace_matrix_cc_df, id.vars = "Position", variable.name = "Channel", value.name = "Intensity")

# Convert the deconvoluted trace matrix to a data frame
trace_matrix_deconv_df <- as.data.frame(deconv_matrix)
trace_matrix_deconv_df$Position <- 1:nrow(deconv_matrix) # Add a position column
trace_matrix_deconv_long <- reshape2::melt(trace_matrix_deconv_df, id.vars = "Position", variable.name = "Channel", value.name = "Intensity")


# Plot the original trace matrix
p1 <- ggplot(trace_matrix_long[trace_matrix_long$Position > 0 &
    trace_matrix_long$Position < 1000, ], aes(x = Position, y = Intensity, color = Channel)) +
    geom_line() +
    labs(title = "Original Trace Matrix", x = "Position", y = "Intensity") +
    theme_minimal()

# Plot the corrected trace matrix
p2 <- ggplot(trace_matrix_cc_long[trace_matrix_cc_long$Position > 0 &
    trace_matrix_cc_long$Position < 1000, ], aes(x = Position, y = Intensity, color = Channel)) +
    geom_line() +
    labs(title = "Corrected Trace Matrix", x = "Position", y = "Intensity") +
    theme_minimal()

# Plot the deconvoluted trace matrix
p3 <- ggplot(trace_matrix_deconv_long[trace_matrix_deconv_long$Position > 0 &
    trace_matrix_deconv_long$Position < 1000, ], aes(x = Position, y = Intensity, color = Channel)) +
    geom_line() +
    labs(title = "Deconvoluted Trace Matrix", x = "Position", y = "Intensity") +
    theme_minimal()

# Print the plots
plot_grid(p1, p2, p3, ncol = 1)


# That's it!!!!!!!!!!!!!