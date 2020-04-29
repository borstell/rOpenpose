# rOpenpose
R scripts for working with Openpose data


# Openpose
[Openpose](https://github.com/CMU-Perceptual-Computing-Lab/openpose/blob/master/README.md) is a fantastic piece of software used for pose estimation of human bodies in image/video data. It has gained a lot of attention in sign language and gesture research recently. I have used it myself in some of my previous work, with collaborators from computational linguistics and computer science introducing it it me.

The software can be a little bit tricky to use if you don't have experience with slightly more technical methods and tools, but if you happen to get your hands on some Openpose data in the form of `.json` files, then perhaps this script can help you work with that data.

# JSON data
Openpose outputs one `.json` file per image (or frame, if video). This format is a machine-readable hierarchical tree structure similar to e.g. `XML`, which you may know. Below is an example of what a raw `.json` file may look like, this one generated from Openpose. (NB: All examples here are based on the analysis of a [Chinese Sign Language sign for 'strong'](https://media.spreadthesign.com/video/mp4/35/383920.mp4) from [_Spread the Sign_](https://www.spreadthesign.com):

```
{"version":1.2,"people":[{"pose_keypoints_2d":[0.484776,0.26635,0.888864,0.513598,0.498695,0.862512,0.37366,0.505003,0.819735,0.354215,0.814579,0.81368,0,0,0,0.634604,0.49242,0.893202,0.67313,0.801499,0.875049,0.687583,1.01459,0.106705,0.518418,1.01446,0.173554,0.436293,1.0145,0.209211,0,0,0,0,0,0,0.600737,1.01448,0.210966,0,0,0,0,0,0,0.455769,0.234105,0.909734,0.5185,0.227986,0.976331,0.431598,0.28569,0.853877,0.562036,0.27947,0.951146,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"face_keypoints_2d":[0.429674,0.247286,0.821682,0.431856,0.269605,0.837714,0.43331,0.291923,0.808108,0.438399,0.314242,0.788037,0.444215,0.33365,0.781932,0.451485,0.354998,0.77055,0.463118,0.369554,0.733813,0.479112,0.379257,0.810471,0.496561,0.380228,0.808284,0.514009,0.378287,0.764461,0.52855,0.365672,0.734319,0.54309,0.353057,0.733609,0.553268,0.33462,0.745657,0.558357,0.315212,0.734339,0.561266,0.292894,0.808568,0.561266,0.268634,0.800876,0.561266,0.244375,0.771205,0.439126,0.216234,0.866277,0.446396,0.20653,0.830789,0.456574,0.201678,0.947456,0.46748,0.201678,0.955243,0.477658,0.20653,0.867206,0.497288,0.202649,0.877945,0.507466,0.196826,0.856603,0.518371,0.193915,0.846824,0.52855,0.198767,0.771201,0.537274,0.209441,0.748339,0.487836,0.23176,0.860272,0.488563,0.244375,0.866484,0.48929,0.255049,0.92679,0.490017,0.264753,0.850179,0.479112,0.28416,0.856892,0.484928,0.286101,0.95299,0.491471,0.286101,0.984882,0.497288,0.28416,0.907035,0.503104,0.280279,0.894254,0.451485,0.237582,0.898252,0.457301,0.23273,0.940305,0.466026,0.23273,0.876616,0.471842,0.238553,0.831384,0.465299,0.240493,0.891729,0.457301,0.240493,0.967782,0.506012,0.23273,0.846213,0.512555,0.225938,0.862929,0.519825,0.225938,0.953254,0.526368,0.23273,0.972003,0.520552,0.234671,0.928373,0.513282,0.235642,0.877658,0.473296,0.322005,0.886162,0.479839,0.310361,0.983168,0.487836,0.303568,0.856777,0.493652,0.304538,0.836473,0.498015,0.302598,0.898414,0.508193,0.30842,0.900247,0.514736,0.317153,0.913772,0.50892,0.325887,0.911326,0.502377,0.331709,0.93155,0.495834,0.332679,0.907686,0.488563,0.332679,0.888446,0.479839,0.329768,0.876912,0.477658,0.320064,0.87534,0.488563,0.312301,0.82797,0.494379,0.312301,0.83155,0.500923,0.310361,0.849198,0.511828,0.317153,0.895586,0.50165,0.322005,0.821763,0.495107,0.322975,0.852344,0.488563,0.322005,0.82782,0.462391,0.234671,0.893625,0.515463,0.23079,0.909055],"hand_left_keypoints_2d":[0.703548,1.02628,0.0290274,0.680297,1.03203,0.0224457,0.672546,1.01594,0.0196746,0.664795,1.07111,0.0137579,0.688047,1.07111,0.00761758,0.662212,1.06996,0.0161054,0.672546,1.0918,0.00972549,0.683741,1.0941,0.00883762,0.702687,1.0964,0.0062458,0.657906,1.06996,0.00925856,0.68288,1.0941,0.00670404,0.687186,1.09525,0.00716413,0.68977,1.0941,0.00508804,0.652739,1.07111,0.00874699,0.688908,1.0964,0.00834783,0.690631,1.09755,0.00914332,0.695798,1.0964,0.00622155,0.724217,1.09755,0.0108499,0.722494,1.07456,0.00833941,0.706132,1.0987,0.00835385,0.713021,1.09525,0.0064826],"hand_right_keypoints_2d":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"pose_keypoints_3d":[],"face_keypoints_3d":[],"hand_left_keypoints_3d":[],"hand_right_keypoints_3d":[]}]}
```

This is a little busy and hard to read, but if indented it is much easier for humans to read. Below is the top part of the previous file but indented to show the structure.

```
{"version":1.2,"people":

  [
    {"pose_keypoints_2d":
      [0.484776,0.26635,0.888864,
      0.513598,0.498695,0.862512,
      0.37366,0.505003,0.819735,
      0.354215,0.814579,0.81368,
        ...]
    }
  ]
}
```

Here, I have manually separated the values in groups of three, since that reflects the Openpose output (see the [Openpose documentation](https://github.com/CMU-Perceptual-Computing-Lab/openpose/blob/master/doc/output.md) for more details on the data formats). Basically, the first group is keypoint `0`, which refers to the nose. The first value is the `x` coordinate, the second is the `y` coordinate, and the third is the `ci` value, which means _confidence interval_ and shows how certain Openpose is that the keypoint position was accurately estimated. Thus, in this example, we get that 
    
      x=0.484776
      y=0.26635
      ci=0.888864
      
which means that Openpose is about 89% certain that the nose is located at approximately (0.48, 0.27). Note that this output uses values between 0 and 1 for the image/video dimensions, but exact pixel values can also be used (e.g. 320x240).

# Reading the files
The R script in this repository reads each `.json` file in a directory and transforms them into one single long format table, like this.

```
> head(keys)
         x        y bodypart frame
1 0.484776 0.266350        0     1
2 0.513598 0.498695        1     1
3 0.373660 0.505003        2     1
4 0.354215 0.814579        3     1
5 0.000000 0.000000        4     1
6 0.634604 0.492420        5     1
```

This can be used for many things, but each individual keypoint (or `bodypart`, as it is rendered here) gets a separate row. In some cases, it may be easier to read each frame as a single row. This is done by transforming the data into a wide format tibble.

```
> head(keys)
# A tibble: 6 x 51
# Groups:   frame [6]
  frame   x_0   x_1   x_2   x_3   x_4   x_5   x_6   x_7   x_8   x_9  x_10  x_11  x_12
  <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
1     1 0.485 0.514 0.374 0.354 0     0.635 0.673 0.688 0.518 0.436     0     0 0.601
2     2 0.485 0.514 0.374 0.354 0     0.635 0.673 0.688 0.518 0.436     0     0 0.601
3     3 0.485 0.514 0.374 0.354 0     0.635 0.673 0.688 0.518 0.436     0     0 0.601
4     4 0.485 0.514 0.374 0.354 0     0.635 0.673 0.688 0.519 0.436     0     0 0.605
5     5 0.485 0.514 0.374 0.354 0     0.635 0.673 0.688 0.518 0.436     0     0 0.601
6     6 0.485 0.514 0.374 0.354 0.335 0.635 0.673 0.688 0.519 0.436     0     0 0.601
# … with 37 more variables:

```

In this format, it is easy to access a specific coordinate value for a specific frame. Say you want to get `(x, y)` for the nose (keypoint `0`) for the very first frame:

```
> c(keys$x_0[1], keys$y_0[1])
[1] 0.484776 0.266350
```

# Plotting
I added some examples of how to plot the data with a makeshift `ggplot2` generated avatar around the keypoints. Mostly for fun, I made some GIFs of this, with some parameters to be changed to alter the appearance of the avatar.

## Basic
![](https://raw.githubusercontent.com/borstell/rOpenpose/master/openpose_pers0.gif)

## Changing color palette
![](https://raw.githubusercontent.com/borstell/rOpenpose/master/openpose_pers1.gif)

## Changing clothes

### Turtleneck
![](https://raw.githubusercontent.com/borstell/rOpenpose/master/openpose_pers2.gif)

### Fancy
![](https://raw.githubusercontent.com/borstell/rOpenpose/master/openpose_pers3.gif)


