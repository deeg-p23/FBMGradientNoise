## Introduction
This is an implementation for 3D gradient (simplex) noise in Unity HLSL, which was derived from 2D perlin & simplex noise implementations I previously put together in ShaderLab for my final project submission for CSE 167 at UCSD.
The noise also uses Fractional Brownian motion to increase the variability of the output. Below are a few materials made in Unity using the shader.

<p align="center">
  <img src="https://github.com/user-attachments/assets/1092c855-71ff-47e1-a0c5-a39dab51f12b" alt="SimplexNoise1">
</p>
<p align="center">
  <img src="https://github.com/user-attachments/assets/13e16bf9-acb5-439a-b20c-6aedb40aa567" alt="SimplexNoise2">
</p>

The following sections are from my original report for CSE 167 on gradient noise. It's a lot of rough explanations as to how it works, so feel free to just skim through to look at the pretty .GIFs.
Additionally, [here is the link to the Shadertoy](https://www.shadertoy.com/view/lctfW2).

-----

## Gradient Noise

I used my Shadertoy project as a vessel for me to begin learning more about various algorithms of Procedural Generation. I initially wanted to delve into more complex and modern methods, like Wave Function Collapse, but realized that would be a little too tough to conquer as of right now. I instead opted for learning more about noise, specifically **Gradient Noise**, in hopes of creating some decently looking procedurally generated contours.

### Perlin Noise

Gradient Noise was for the most part conceived by Ken Perlin’s development of **Perlin Noise**, which still remains to be (probably) the most well known procedural texturing function. To start my project, I tried my hand at implementing it.

Perlin Noise takes the screen, defines a grid full of cells, and for every fragment, takes 5 steps:
1. Gets all four corners that make up the cell that the fragment lies in.
2. Pseudo-randomly generates a gradient per corner.
3. Per corner, computes the dot product of fragment-to-corner distance and the gradient.
4. Inputs original UV coordinates into a fading function to get interpolation weights.
5. Interpolates same-x corners with weight X, and interpolate those results with weight Y.

The procedure is a bit different in different dimensions. For example in 1D, cells are only 2 corners in 1D, so they only need to be interpolated once x-wise. In 3D, cells have 8 corners, needing to be interpolated four times x-wise, twice y-wise, and once z-wise.

I set a few custom properties, such as the scale of the UV screen, and speed at which the gradients change angles over time. It initially gave the messy output on the left, so for more clarity, the fragment color was altered to multiply the resultant noise by value, and an inverse sharpness, which gave the cleaner output on the right.

<p align="center">
  <img src="https://github.com/user-attachments/assets/ca4bc300-4bdc-4d56-a473-c2311ec910a1"  alt="GradientNoise1"  width="49%">
  <img src="https://github.com/user-attachments/assets/4511bc9c-5825-4e31-b838-3bced6ae42eb" alt="GradientNoise2" width="49%">
</p>

## Simplex Noise

The next step in my Gradient Noise journey was to understand and implement **Simplex Noise**, the evolved younger brother of Perlin Noise (also developed by Ken Perlin much later). Simplex Noise is significantly less comprehensive than Perlin Noise, but has benefits in having improvements regarding computation speeds, dimensionality, and feature clarity (I care significantly more about the last one in pursuit of pretty shader art).

Simplex Noise takes a screen, and for every fragment, takes 5 steps:
1. Transforms UV inputs into a grid of skewed triangular simplexes.
2. Gets the distance between the fragment and the first corner by un-skewing the coords.
3. Determines the other two corner distances by un-skewing first corner offsets.
4. Pseudo-randomly generate a gradient per corner.
5. Compute a sum of contributions between each corner to the point.

Once again, the procedure is slightly altered under other dimensions, having (N+1) corners in a simplex to account for N dimensions, adding a little more computation to steps 3, 4, and 5. The burden of conceptually grasping Simplex Noise was lightened quite a lot by reading through **_Simplex noise demystified_** (2005) by Stefan Gustavson a good few times.

Now, the noise has a bit more contrast between whitened and darkened spots, and the orientation of the gradients are skewed a little bit compared to Perlin Noise. Since Simplex Noise has a completely separate process, I added a property to switch between the two modes when generating noise.

<p align="center">
  <img src="https://github.com/user-attachments/assets/d44c05d1-cfbc-489a-8749-942e267696c7" alt="GradientNoise3" width="49%">
</p>

## Fractional Brownian Motion

The next step was finding ways to stylize the look of Simplex Noise. **Fractional Brownian Motion (FBM)**, at least in applications of Noise, iteratively sums the values of noise from N layers of generated noise that differ by amplitude and frequency. The amplitude varies by a product of itself and **persistence** in every layer, and frequency varies by a product of itself and **lacunarity** in every layer. 

So for every layer, the evaluated noise now takes UV * frequency as the fragment coordinates, and has its result multiplied by amplitude and added to the noise sum, producing outputs like these two. The upper figure has significantly altered base frequency and amplitude, and the lower has significantly altered the persistence and lacunarity, which is evident in the almost fractal-like nature of the splotchy edges.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a5e16403-fa60-4fa2-b301-d7c01ad21b3a"  alt="GradientNoise4"  width="49%">
  <img src="https://github.com/user-attachments/assets/739a5ff9-09bb-4b82-ab9c-41c94b4e33a8" alt="GradientNoise5" width="49%">
</p>


## Color Mapping

The final step was of course some color. I modified a [palette interpolation function](https://www.shadertoy.com/view/ll2GD3) created by Inigo Quilez to alter the resulting fragment color based on four palette vectors, and the resulting FBM noise as the interpolation factor, t. Using Perlin Noise, a mix of the FBM properties shown in the previous two figures, and some vibrant heat-like palette vectors, I ended the project with this visual.

<p align="center">
  <img src="https://github.com/user-attachments/assets/07d2d1ed-109a-45b0-ba25-5f5641aeba3a" alt="GradientNoise6" width="75%">
</p>

The journey getting here was very refreshing. Where I hoped to create a more stylistically inspired shader with this project, I instead learned incredibly new things about the world of procedural generation, all while improving shader writing skills. I’m hoping to continue working with stylized noise, likely with 3D objects next. 

Thanks!

- Diego Pereyra
