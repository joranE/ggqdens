StatDensityQuantile <-
  ggproto("StatDensityQuantile", StatDensity,
          setup_params =
            function(data, params) {
              params <- StatDensity$setup_params(data, params)
              if (is.null(params$quantiles)) {
                params$quantiles <- numeric()
              }
              params
            },

          compute_group =
            function(data, scales, bw = "nrd0", adjust = 1,
                     kernel = "gaussian", n = 512, trim = FALSE,
                     na.rm = FALSE, quantiles = NULL) {

              # Get the density estimate data
              dens <- stats::density(
                data$x,
                bw = bw,
                adjust = adjust,
                kernel = kernel,
                n = n,
                na.rm = na.rm)

              # Create the density data frame
              density_df <- data.frame(
                x = dens$x,
                density = dens$y,
                scaled = dens$y,
                count = dens$y * sum(!is.na(data$x)),
                n = length(dens$x),
                group = 1,
                is_density = TRUE,
                quantile_idx = 0  # Add index for matching aesthetics
              )

              # If no quantiles requested, return just the density data
              if (length(quantiles) == 0) {
                return(density_df)
              }

              # Calculate quantiles
              quant_x <- stats::quantile(data$x, probs = quantiles, na.rm = TRUE)

              # For each quantile value, create a vertical line data
              quant_dfs <- lapply(seq_along(quant_x), function(i) {
                x_val <- quant_x[i]
                # Find corresponding density value
                y_val <- approx(density_df$x, density_df$density, xout = x_val)$y

                data.frame(
                  x = rep(x_val, 2),
                  density = c(0, y_val),
                  scaled = c(0, y_val),
                  count = c(0, y_val * sum(!is.na(data$x))),
                  n = 2,
                  group = i + 1,
                  is_density = FALSE,
                  quantile_idx = i  # Store index for matching aesthetics
                )
              })

              # Combine all data
              do.call(rbind, c(list(density_df), quant_dfs))
            }
  )
