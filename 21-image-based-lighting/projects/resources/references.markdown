## Physically Based Rendering

[Allegorithmic: The Theory of Physically-Based Rendering and Shading](https://www.allegorithmic.com/pbr-guide)

[SIGGRAPH University - Introduction to "Physically Based Shading in Theory and Practice" by Naty Hoffman](https://youtu.be/j-A0mwsJRmk)


## Create your own skybox textures

### 1. Find a texture

Find an equirectangular environment map. This is a texture which has the full 360º view projected onto it. 

**Sources of environment maps:**

[http://hdrihaven.com](http://hdrihaven.com) 100% free and licenced CC0

[http://www.hdrlabs.com/sibl/archive.html](http://www.hdrlabs.com/sibl/archive.html) free, but licenced as Creative Commons Attribution-Noncommercial-Share Alike 3.0.

**Using your own pictures:**

Download [Google StreetView app](https://itunes.apple.com/us/app/google-street-view/id904418768?mt=8). Find an uncrowded place such as a park or the beach and use the app to create the 360º image.

### 2. Convert the texture to a jpg

If you're converting a hdri, conversion loses the high dynamic range values, so you can use the result as a sky texture, but it is not good for lighting. (hdr files contain rgb values higher than 1.0)

You can convert hdris using Preview, however in an app such as Affinity Photo, you can do tone mapping to bring the high dynamic range into the jpg's low dynamic range. 

### 3. Extract six square textures from the map

Upload the image to: [https://jaxry.github.io/panorama-to-cubemap/](https://jaxry.github.io/panorama-to-cubemap/), convert and download the six cube faces.

Alternatively, to convert on your own computer, go to: [https://aerotwist.com/tutorials/create-your-own-environment-maps/](https://aerotwist.com/tutorials/create-your-own-environment-maps/) and download from the **CONVERT TO CUBE** section the Blender file. This Blender file will convert an equirectangular file called **environment.jpg**. Follow the instructions in that section to create the six images. These will have numbered file names, but the page describes which number equates to which cube face.

### 4. Import the texture

In your project, create a cube texture in the asset catalog, and drag the six images into their appropriate locations.

## Epic Games and rendering in Fortnite

Epic developed an approachable rendering system adapted from Disney's physically based shading algorithms: 

* Video (bad quality): [https://www.youtube.com/watch?v=fJz0GgarVTo](https://www.youtube.com/watch?v=fJz0GgarVTo)
* Slides: [http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_slides.pdf](http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_slides.pdf)
* Paper: [http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf](http://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf). 

This is now widely adopted, and is explained well at:

[https://learnopengl.com/PBR/IBL/Diffuse-irradiance](https://learnopengl.com/PBR/IBL/Diffuse-irradiance) 

[https://learnopengl.com/PBR/IBL/Specular-IBL](https://learnopengl.com/PBR/IBL/Specular-IBL)

## Loading hdris

You can download a public domain image loader from: [https://github.com/nothings/stb/blob/master/stb_image.h](https://github.com/nothings/stb/blob/master/stb_image.h).

GLTFKit from Warren Moore contains Metal code that uses this image loader to load an hdr image image and also has kernels to convolve the result for irradiance maps. [https://github.com/warrenm/GLTFKit](https://github.com/warrenm/GLTFKit)

You can use **cmft** to produce radiance and irradiance maps from hdris. Xcode still won't read the results without conversion though. [https://github.com/dariomanesku/cmft](https://github.com/dariomanesku/cmft)

## Spherical Harmonics

I've included a lot of references here, because although SH are easy to use, they are complex to understand.

[Weta Digital Spherical Harmonics Explanation](https://www.fxguide.com/featured/the-science-of-spherical-harmonics-at-weta-digital/)

[An Efficient Representation for Irradiance Environment Maps by Ravi Ramamoorthi and Pat Hanrahan](https://cseweb.ucsd.edu/~ravir/papers/envmap/)

[Spherical Harmonic Lighting: The Gritty Details](http://silviojemma.com/public/papers/lighting/spherical-harmonic-lighting.pdf)

[Stupid Spherical Harmonics tricks by Peter-Pike Sloan](https://www.ppsloan.org/publications/StupidSH36.pdf)

[Physically Based Rendering for Artists](https://youtu.be/LNwMJeWFr0U)

[Spherical Harmonics for Dummies](https://math.stackexchange.com/questions/24671/spherical-harmonics-for-dummies)

[Spherical Harmonics by Volker Schönefeld](http://limbicsoft.com/volker/prosem_paper.pdf)

## Further reading

[Videos from MIT Computer Graphics 6.837, September 2017](https://www.youtube.com/user/justinmsolomon/videos)
