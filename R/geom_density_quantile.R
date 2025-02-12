#' Density with quantiles
#'
#' Extension of `geom_density` that allows for vertical quantile lines.
#'
#' @inheritParams ggplot2::geom_density
#' @param quantiles numeric; vector of quantile locations
#' @param quantile_color character; vector of colors
#' @param quantile_linewidth numeric; vector of linewidths
#' @param quantile_linetype character; vector of line types
#' @import ggplot2
#' @import grid
#' @export
geom_density_quantile <- function(mapping = NULL, data = NULL,
                                   position = "identity", ...,
                                   quantiles = NULL,
                                   quantile_color = "red",
                                   quantile_linewidth = 0.5,
                                   quantile_linetype = "dashed",
                                   na.rm = FALSE,
                                   show.legend = NA,
                                   inherit.aes = TRUE) {
  params <- list(
    na.rm = na.rm,
    quantiles = quantiles,
    quantile_color = quantile_color,
    quantile_linewidth = quantile_linewidth,
    quantile_linetype = quantile_linetype,
    ...
  )

  layer(
    data = data,
    mapping = mapping,
    stat = StatDensityQuantile,
    geom = GeomDensityQuantile,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = params
  )
}


GeomDensityQuantile <-
  ggproto("GeomDensityQuantile", GeomLine,
          required_aes = c("x", "y"),

          setup_data = function(data, params) {
            data$y <- data$density
            data
          },

          parameters = function(extra = FALSE) {
            # Include the parameters from GeomLine
            line_params <- GeomLine$parameters(extra)

            # Add our custom parameters
            c(line_params,
              "quantile_colour",
              "quantile_linewidth",
              "quantile_linetype",
              "quantiles")
          },

          draw_panel = function(self, data, panel_params, coord,
                                quantile_colour = "red",
                                quantile_linewidth = 0.5,
                                quantile_linetype = "dashed",
                                quantiles = NULL,
                                na.rm = FALSE,
                                flipped_aes = FALSE) {

            # Validate and recycle aesthetic vectors
            n_quantiles <- length(quantiles)
            if (n_quantiles > 0) {
              check_length <- function(x, name) {
                len <- length(x)
                if (len != 1 && len != n_quantiles) {
                  stop(sprintf("%s must be of length 1 or %d (length of quantiles)", name, n_quantiles))
                }
                if (len == 1) rep(x, n_quantiles) else x
              }

              quantile_colour <- check_length(quantile_colour, "quantile_colour")
              quantile_linewidth <- check_length(quantile_linewidth, "quantile_linewidth")
              quantile_linetype <- check_length(quantile_linetype, "quantile_linetype")
            }

            groups <- split(data, data$group)

            grobs <- lapply(groups, function(group) {
              self$draw_group(
                data = group,
                panel_params = panel_params,
                coord = coord,
                quantile_colour = quantile_colour,
                quantile_linewidth = quantile_linewidth,
                quantile_linetype = quantile_linetype,
                na.rm = na.rm,
                flipped_aes = flipped_aes
              )
            })

            ggplot2:::ggname("geom_density_quantiles", grid::gTree(children = do.call("gList", grobs)))
          },

          draw_group = function(data, panel_params, coord,
                                quantile_colour = "red",
                                quantile_linewidth = 0.5,
                                quantile_linetype = "dashed",
                                na.rm = FALSE,
                                flipped_aes = FALSE) {

            # Transform all data
            positions <- coord$transform(data, panel_params)

            # Check if this is a density group or quantile group
            if (positions$is_density[1]) {
              # Create the density line grob
              grid::polylineGrob(
                positions$x,
                positions$y,
                default.units = "native",
                gp = grid::gpar(col = positions$colour[1],
                          lwd = positions$linewidth[1] * .pt,
                          lty = positions$linetype[1])
              )
            } else {
              # Get the index for this quantile to match with aesthetics
              idx <- positions$quantile_idx[1]

              # Create quantile line grob with specific aesthetics
              grid::linesGrob(
                x = grid::unit(rep(positions$x[1], 2), "native"),
                y = grid::unit(c(0, positions$y[2]), "native"),
                gp = grid::gpar(
                  col = quantile_colour[idx],
                  lwd = quantile_linewidth[idx] * .pt,
                  lty = quantile_linetype[idx]
                )
              )
            }
          }
  )
