library(jsonlite)
library(tidyverse)
library(ggforce)
library(gganimate)

# Function for quickly calculating Euclidean distance between two points
coord_dist <- function(x1,y1, x2, y2) {
  return(sqrt((x1-x2)^2+(y1-y2)^2))
}

# Path to folder with json files
path <- "/path/to/openpose_json_files/"

# Get Openpose .json output files
filenames = list.files(path = path, pattern="*.json")

# Read the Openpose .json output files and save to data list
datalist = list()
n <- 0
for (f in filenames){
  pose <- fromJSON(paste0(path, f))
  kp <- pose$people$pose_keypoints_2d[[1]] # Read data from first person in .json
  keys <- data.frame(x=kp[c(TRUE, FALSE, FALSE)]) # Reads x coordinates
  keys <- data.frame(keys, y=kp[c(FALSE, TRUE, FALSE)]) # Reads y coordinates
  #keys <- data.frame(keys, ci=kp[c(FALSE, FALSE, TRUE)]) # Reads confidence intervals (ci). (Uncomment if you want to include them)
  keys <- data.frame(keys, bodypart=1:(length(kp)/3)-1)
  keys$frame <- n+1
  datalist[[n+1]] <- keys
  n <- n+1
}

# Bind the individual files read together in one data set
keys <- dplyr::bind_rows(datalist)

# Transform long format to wide format to make each frame a single row 
#   (each keypoint as columns: x, y)
keys <- keys %>% 
  group_by(frame, x, y, bodypart) %>% 
  pivot_wider(names_from = bodypart, values_from = c(x, y))

# Set any zero values to NA 
#   (NB: There may be zero values you want to keep)
keys <- na_if(keys, 0)

# Transform data to data frame
keys <- data.frame(keys)

# Fill NA values by transferring values regressively and progressively (respectively) 
# (NB: Only do this to fill data necessary for visualizing smooth(ish) movements)
keys <- keys %>% 
  fill(.direction = "up", everything()) %>% 
  fill(everything()) %>% 
  select_if(~ !any(is.na(.)))

# Plot all frames

## Some individual color parameters to be set
skin <- "lightgrey"
#skin <- "tan4"
clothes <- "lightgrey"
#clothes <- "moccasin"
hat <- "black"
rh <- skin
lh <- skin
clothes_alpha <- .05
hat_alpha <- 0
turtle_alpha <- 0
monocle_alpha <- 0

ggplot(keys) +
  #geom_point(aes(x=x, y=y), size=3) +
  # Head
  #geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(x_0, y_0, x_18, y_18), b = coord_dist(x_0, y_0, x_18, y_18)*1.4, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.1, b = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.6, angle=0), fill = skin, alpha=1, linetype=0) +
  # Monocle
  geom_point(aes(x=x_0-0.025, y=y_0), color="black", shape=21, size=6, alpha=monocle_alpha) +
  # Tophat
  geom_rect(aes(xmin = x_0-0.1, ymin = y_0/1.4, xmax = x_0+0.1, ymax = y_0/1.4+0.05), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  geom_rect(aes(xmin = x_0-0.07, ymin = y_0/1.4, xmax = x_0+0.07, ymax = y_0/1.4-0.15), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  # Turtleneck
  geom_rect(aes(xmin = x_0-0.05, ymin = y_1/1.1, xmax = x_0+0.05, ymax = y_1/1.1-0.08), fill = clothes, alpha=turtle_alpha, size=13, linejoin = "round") +
  # Chest
  #geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_2, y_2, x_1, y_1)*.7, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1))*.7, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Torso
  #geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(y_0-y_8)*.3, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_1, y_1, x_8, y_8)*.45, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(mean(y_0)-mean(y_8))*.3, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_1), mean(y_1), mean(x_8), mean(y_8))*.45, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Left + Right shoulder
  geom_ellipse(aes(x0 = x_2, y0 = y_2, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  geom_ellipse(aes(x0 = x_5, y0 = y_5, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Right arm (upper, lower, hand)
  geom_segment(aes(x = x_2, y = y_2, xend = x_3, yend = y_3), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_3, y = y_3, xend = x_4, yend = y_4), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_4, y0 = y_4, a = .05, b =  .05, angle=0), fill = rh, alpha=1, linetype=0) +
  # Left arm (upper, lower, hand)
  geom_segment(aes(x = x_5, y = y_5, xend = x_6, yend = y_6), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_6, y = y_6, xend = x_7, yend = y_7), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_7, y0 = y_7, a = .05, b =  .05, angle=0), fill = lh, alpha=1, linetype=0) +
  xlim(0,1) + ylim(0,1) + 
  scale_y_reverse() + 
  coord_fixed() +
  theme_void()



# Make animated .gifs with some variations on colors etc

skin <- "lightgrey"
#skin <- "tan4"
clothes <- "lightgrey"
#clothes <- "moccasin"
hat <- "black"
rh <- skin
lh <- skin
clothes_alpha <- .95
hat_alpha <- 0
turtle_alpha <- 0
monocle_alpha <- 0

pers0 <- ggplot(keys) +
  #geom_point(aes(x=x, y=y), size=3) +
  # Head
  #geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(x_0, y_0, x_18, y_18), b = coord_dist(x_0, y_0, x_18, y_18)*1.4, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.1, b = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.6, angle=0), fill = skin, alpha=1, linetype=0) +
  # Monocle
  geom_point(aes(x=x_0-0.025, y=y_0), color="black", shape=21, size=6, alpha=monocle_alpha) +
  # Tophat
  geom_rect(aes(xmin = x_0-0.1, ymin = y_0/1.4, xmax = x_0+0.1, ymax = y_0/1.4+0.05), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  geom_rect(aes(xmin = x_0-0.07, ymin = y_0/1.4, xmax = x_0+0.07, ymax = y_0/1.4-0.15), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  # Turtleneck
  geom_rect(aes(xmin = x_0-0.05, ymin = y_1/1.1, xmax = x_0+0.05, ymax = y_1/1.1-0.08), fill = clothes, alpha=turtle_alpha, size=13, linejoin = "round") +
  # Chest
  #geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_2, y_2, x_1, y_1)*.7, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1))*.7, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Torso
  #geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(y_0-y_8)*.3, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_1, y_1, x_8, y_8)*.45, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(mean(y_0)-mean(y_8))*.3, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_1), mean(y_1), mean(x_8), mean(y_8))*.45, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Left + Right shoulder
  geom_ellipse(aes(x0 = x_2, y0 = y_2, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  geom_ellipse(aes(x0 = x_5, y0 = y_5, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Right arm (upper, lower, hand)
  geom_segment(aes(x = x_2, y = y_2, xend = x_3, yend = y_3), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_3, y = y_3, xend = x_4, yend = y_4), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_4, y0 = y_4, a = .05, b =  .05, angle=0), fill = rh, alpha=1, linetype=0) +
  # Left arm (upper, lower, hand)
  geom_segment(aes(x = x_5, y = y_5, xend = x_6, yend = y_6), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_6, y = y_6, xend = x_7, yend = y_7), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_7, y0 = y_7, a = .05, b =  .05, angle=0), fill = lh, alpha=1, linetype=0) +
  xlim(0,1) + ylim(0,1) + 
  scale_y_reverse() + 
  coord_fixed() +
  theme_void() +
  transition_states(
    frame,
    transition_length = 0,
    state_length = 1) +
  enter_fade() + 
  exit_shrink() +
  ease_aes('sine-in-out')


#skin <- "peachpuff"
skin <- "tan4"
#clothes <- "darkred"
clothes <- "thistle3"
hat <- "black"
rh <- skin
lh <- skin
clothes_alpha <- .95
hat_alpha <- 0
turtle_alpha <- 0
monocle_alpha <- 0

pers1 <- ggplot(keys) +
  # Head
  #geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(x_0, y_0, x_18, y_18), b = coord_dist(x_0, y_0, x_18, y_18)*1.4, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.1, b = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.6, angle=0), fill = skin, alpha=1, linetype=0) +
  # Monocle
  geom_point(aes(x=x_0-0.025, y=y_0), color="black", shape=21, size=6, alpha=monocle_alpha) +
  # Tophat
  geom_rect(aes(xmin = x_0-0.1, ymin = y_0/1.4, xmax = x_0+0.1, ymax = y_0/1.4+0.05), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  geom_rect(aes(xmin = x_0-0.07, ymin = y_0/1.4, xmax = x_0+0.07, ymax = y_0/1.4-0.15), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  # Turtleneck
  geom_rect(aes(xmin = x_0-0.05, ymin = y_1/1.1, xmax = x_0+0.05, ymax = y_1/1.1-0.08), fill = clothes, alpha=turtle_alpha, size=13, linejoin = "round") +
  # Chest
  #geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_2, y_2, x_1, y_1)*.7, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1))*.7, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Torso
  #geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(y_0-y_8)*.3, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_1, y_1, x_8, y_8)*.45, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(mean(y_0)-mean(y_8))*.3, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_1), mean(y_1), mean(x_8), mean(y_8))*.45, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Left + Right shoulder
  geom_ellipse(aes(x0 = x_2, y0 = y_2, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  geom_ellipse(aes(x0 = x_5, y0 = y_5, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Right arm (upper, lower, hand)
  geom_segment(aes(x = x_2, y = y_2, xend = x_3, yend = y_3), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_3, y = y_3, xend = x_4, yend = y_4), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_4, y0 = y_4, a = .05, b =  .05, angle=0), fill = rh, alpha=1, linetype=0) +
  # Left arm (upper, lower, hand)
  geom_segment(aes(x = x_5, y = y_5, xend = x_6, yend = y_6), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_6, y = y_6, xend = x_7, yend = y_7), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_7, y0 = y_7, a = .05, b =  .05, angle=0), fill = lh, alpha=1, linetype=0) +
  xlim(0,1) + ylim(0,1) + 
  scale_y_reverse() + 
  coord_fixed() +
  theme_void() +
  transition_states(
    frame,
    transition_length = 0,
    state_length = 1) +
  enter_fade() + 
  exit_shrink() +
  ease_aes('sine-in-out')


skin <- "peachpuff"
#skin <- "tan4"
clothes <- "darkred"
#clothes <- "moccasin"
hat <- "black"
rh <- skin
lh <- skin
clothes_alpha <- .95
hat_alpha <- 0
turtle_alpha <- 1
monocle_alpha <- 0

pers2 <- ggplot(keys) +
  # Head
  #geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(x_0, y_0, x_18, y_18), b = coord_dist(x_0, y_0, x_18, y_18)*1.4, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.1, b = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.6, angle=0), fill = skin, alpha=1, linetype=0) +
  # Monocle
  geom_point(aes(x=x_0-0.025, y=y_0), color="black", shape=21, size=6, alpha=monocle_alpha) +
  # Tophat
  geom_rect(aes(xmin = x_0-0.1, ymin = y_0/1.4, xmax = x_0+0.1, ymax = y_0/1.4+0.05), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  geom_rect(aes(xmin = x_0-0.07, ymin = y_0/1.4, xmax = x_0+0.07, ymax = y_0/1.4-0.15), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  # Turtleneck
  geom_rect(aes(xmin = x_0-0.05, ymin = y_1/1.1, xmax = x_0+0.05, ymax = y_1/1.1-0.08), fill = clothes, alpha=turtle_alpha, size=13, linejoin = "round") +
  # Chest
  #geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_2, y_2, x_1, y_1)*.7, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1))*.7, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Torso
  #geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(y_0-y_8)*.3, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_1, y_1, x_8, y_8)*.45, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(mean(y_0)-mean(y_8))*.3, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_1), mean(y_1), mean(x_8), mean(y_8))*.45, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Left + Right shoulder
  geom_ellipse(aes(x0 = x_2, y0 = y_2, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  geom_ellipse(aes(x0 = x_5, y0 = y_5, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Right arm (upper, lower, hand)
  geom_segment(aes(x = x_2, y = y_2, xend = x_3, yend = y_3), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_3, y = y_3, xend = x_4, yend = y_4), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_4, y0 = y_4, a = .05, b =  .05, angle=0), fill = rh, alpha=1, linetype=0) +
  # Left arm (upper, lower, hand)
  geom_segment(aes(x = x_5, y = y_5, xend = x_6, yend = y_6), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_6, y = y_6, xend = x_7, yend = y_7), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_7, y0 = y_7, a = .05, b =  .05, angle=0), fill = lh, alpha=1, linetype=0) +
  xlim(0,1) + ylim(0,1) + 
  scale_y_reverse() + 
  coord_fixed() +
  theme_void() +
  transition_states(
    frame,
    transition_length = 0,
    state_length = 1) +
  enter_fade() + 
  exit_shrink() +
  ease_aes('sine-in-out')

skin <- "peachpuff"
#skin <- "tan4"
#clothes <- "darkred"
#clothes <- "moccasin"
clothes <- "black"
hat <- "black"
rh <- skin
lh <- skin
clothes_alpha <- .95
hat_alpha <- 1
turtle_alpha <- 0
monocle_alpha <- 1

pers3 <- ggplot(keys) +
  # Head
  #geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(x_0, y_0, x_18, y_18), b = coord_dist(x_0, y_0, x_18, y_18)*1.4, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_0, a = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.1, b = coord_dist(mean(x_0), mean(y_0), mean(x_18), mean(y_18))*1.6, angle=0), fill = skin, alpha=1, linetype=0) +
  # Monocle
  geom_point(aes(x=x_0-0.025, y=y_0), color="black", shape=21, size=6, alpha=monocle_alpha) +
  # Tophat
  geom_rect(aes(xmin = x_0-0.1, ymin = y_0/1.4, xmax = x_0+0.1, ymax = y_0/1.4+0.05), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  geom_rect(aes(xmin = x_0-0.07, ymin = y_0/1.4, xmax = x_0+0.07, ymax = y_0/1.4-0.15), fill = hat, alpha=hat_alpha, size=13, linejoin = "round") +
  # Turtleneck
  geom_rect(aes(xmin = x_0-0.05, ymin = y_1/1.1, xmax = x_0+0.05, ymax = y_1/1.1-0.08), fill = clothes, alpha=turtle_alpha, size=13, linejoin = "round") +
  # Chest
  #geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_2, y_2, x_1, y_1)*.7, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1))*.7, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Torso
  #geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(y_0-y_8)*.3, a = coord_dist(x_2, y_2, x_1, y_1), b =  coord_dist(x_1, y_1, x_8, y_8)*.45, angle=0), fill = "lightgrey", alpha=1, linetype=0) +
  geom_ellipse(aes(x0 = x_0, y0 = y_1+abs(mean(y_0)-mean(y_8))*.3, a = coord_dist(mean(x_2), mean(y_2), mean(x_1), mean(y_1)), b =  coord_dist(mean(x_1), mean(y_1), mean(x_8), mean(y_8))*.45, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Left + Right shoulder
  geom_ellipse(aes(x0 = x_2, y0 = y_2, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  geom_ellipse(aes(x0 = x_5, y0 = y_5, a = .08, b =  .08, angle=0), fill = clothes, alpha=clothes_alpha, linetype=0) +
  # Right arm (upper, lower, hand)
  geom_segment(aes(x = x_2, y = y_2, xend = x_3, yend = y_3), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_3, y = y_3, xend = x_4, yend = y_4), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_4, y0 = y_4, a = .05, b =  .05, angle=0), fill = rh, alpha=1, linetype=0) +
  # Left arm (upper, lower, hand)
  geom_segment(aes(x = x_5, y = y_5, xend = x_6, yend = y_6), color = clothes, alpha=clothes_alpha, size=15, linejoin = "round") +
  geom_segment(aes(x = x_6, y = y_6, xend = x_7, yend = y_7), color = clothes, alpha=clothes_alpha, size=13, linejoin = "round") +
  geom_ellipse(aes(x0 = x_7, y0 = y_7, a = .05, b =  .05, angle=0), fill = lh, alpha=1, linetype=0) +
  xlim(0,1) + ylim(0,1) + 
  scale_y_reverse() + 
  coord_fixed() +
  theme_void() +
  transition_states(
    frame,
    transition_length = 0,
    state_length = 1) +
  enter_fade() + 
  exit_shrink() +
  ease_aes('sine-in-out')

# Save .gifs (change filename and path as needed)
animate(pers0, nframes = 90, fps = 25, renderer = gifski_renderer("openpose_pers0.gif"), end_pause = 1, rewind = FALSE)
animate(pers1, nframes = 90, fps = 25, renderer = gifski_renderer("openpose_pers1.gif"), end_pause = 1, rewind = FALSE)
animate(pers2, nframes = 90, fps = 25, renderer = gifski_renderer("openpose_pers2.gif"), end_pause = 1, rewind = FALSE)
animate(pers3, nframes = 90, fps = 25, renderer = gifski_renderer("openpose_pers3.gif"), end_pause = 1, rewind = FALSE)
