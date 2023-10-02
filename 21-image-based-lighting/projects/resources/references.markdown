## Physically Based Rendering

[Adobe: The PBR Guide - Part 1](https://substance3d.adobe.com/tutorials/courses/the-pbr-guide-part-1)
[Adobe: The PBR Guide - Part 2](https://substance3d.adobe.com/tutorials/courses/the-pbr-guide-part-2)

[SIGGRAPH University - Physics and Math of Shading" by Naty Hoffman](https://youtu.be/j-A0mwsJRmk)

## Create your own skybox textures

1. Find an equirectangular environment map. This is a texture which has the full 360º view projected onto it. 

A good source of environment maps:

[https://polyhaven.com/hdris](https://polyhaven.com/hdris) 100% free and licenced CC0

2. Upload the image to [https://matheowis.github.io/HDRI-to-CubeMap/](https://matheowis.github.io/HDRI-to-CubeMap/)

3. Choose the layout that downloads six separate .png files.

4. Click Process and then Save.

5. In your project, create a cube texture in the asset catalog, and drag the six images into their appropriate locations.

## Epic Games and rendering in Fortnite

Epic developed an approachable rendering system adapted from Disney's physically based shading algorithms: 

* Video (bad quality): [https://www.youtube.com/watch?v=fJz0GgarVTo](https://www.youtube.com/watch?v=fJz0GgarVTo)
* Slides: [Real Shading in Unreal Engine 4 by Brian Karis, Epic Games](https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_slides.pdf)
* Paper: [Real Shading in Unreal Engine 4 by Brian Karis, Epic Games](https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf)

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

[Spherical Harmonic Lighting: The Gritty Details](https://web.archive.org/web/20181011125928/http://silviojemma.com/public/papers/lighting/spherical-harmonic-lighting.pdf)

[Stupid Spherical Harmonics tricks by Peter-Pike Sloan](https://www.ppsloan.org/publications/StupidSH36.pdf)

[Physically Based Rendering for Artists](https://youtu.be/LNwMJeWFr0U)

[Spherical Harmonics for Dummies](https://math.stackexchange.com/questions/24671/spherical-harmonics-for-dummies)

[Spherical Harmonics by Volker Schönefeld](https://bit.ly/3D5U54R)

## Further reading

[IBLBaker](https://github.com/derkreature/IBLBaker)
