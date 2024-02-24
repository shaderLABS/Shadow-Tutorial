This shader pack includes:
- Shadows (obviously)
- Colored shadows (cast by translucent blocks like stained glass)
- Shadow bias (prevents shadow acne)
- Shadow distortion (higher resolution shadows near the player)
- An example of how to prevent certain blocks from casting shadows.

It does NOT include:
- PCSS
- Volumetric light
- Custom light colors (it just uses the vanilla lightmap instead)
- Block shading

## How do shadows (in general) work?
The first thing you'll need is called a shadow map.
This is, roughly speaking, a picture of the world from the perspective of the sun, instead of the player.
In minecraft, the shadow pass renders first before everything else.
While the shadow pass is running, shadow.fsh/vsh will be used to draw things.
shadow.fsh is responsible for writing colors to the shadow map if needed.
After the shadow pass is done, the normal pass becomes active, starting with the gbuffers programs.

All programs (except shadow) have access to the shadow map in the form of (up to) 4 different samplers:
- `shadowcolor0`: Contains whatever data shadow.fsh wrote to `gl_FragData[0]`.
- `shadowcolor1`: Contains whatever data shadow.fsh wrote to `gl_FragData[1]`.
- `shadowtex0`: Works like `depthtex0`, but for the shadow map. It contains the distance to the closest thing to the sun.
- `shadowtex1`: Works like `depthtex1`; it contains the distance to the closest OPAQUE thing to the sun.

The primary sampler that later programs will use is `shadowtex0`.
Since `shadowtex0` tells you the distance to the closest thing to the sun,
other programs can use this to determine whether or not something is *visible* from the sun.
If something is not visible from the sun, then shadows should be drawn at that location.
Optionally, if something is visible from the sun, you can also increase its brightness to the max even if it has a low skylight level.

## So, how can shaders use the shadow map in practice?
The shadow map has the camera moved to a different position than normal.
As such, you can't just sample `shadowtex0` at texcoord.
Instead, you have to transform the current player-space vector into shadow-space.
Optifine has matrixes for this: `shadowModelView` and `shadowProjection` (both uniform mat4's).
As you probably know by now, screenspace positions for vertexes are in the range -1 to +1,
but textures are sampled in the range 0 to 1.
As such, you'll need to convert this range when you sample `shadowtex0`.
Anyway, once you have your position in shadow space,
all you need to do is compare the depth of that position to the depth of the shadow map (`shadowtex0`).

Usually, you'll want to do this wherever your lighting code is.
Depending on your pipeline, you might want to handle it in gbuffers,
or maybe your pipeline is more deferred than that,
in which case putting it in composite is a better option.
This example pack draws shadows on top of things in `gbuffers_textured`.
It also draws shadows by just changing lmcoord. Nothing fancy here.

## How do colored shadows work?
Colored shadows work just like regular shadows, but instead of just testing `shadowtex0`, you also test `shadowtex1`.
Since `shadowtex1` only contains opaque geometry, sampling this will tell you if you need to apply "normal" (non-colored) shadows or not.
If you don't need to apply normal shadows, try colored shadows via `shadowtex0` next.
`shadowcolor0` or `shadowcolor1` can then be used to determine what color the shadow should be.
This can then be mixed or multiplied by the albedo in whatever way suits your desire.

## What is shadow bias, and why is it needed?
Assume your surface is visible to the sun.
When computing its depth in shadow space, you'd expect to get the same value as you'd get from sampling `shadowtex0`, right?
Wrong. Unfortunately, we don't live in such a perfect world.

There's a little thing called floating point precision that tends to mess up a lot of things here.
In this case, the depth you get according to your shadow space position will be slightly different than the depth of the shadow map.
It might be a little bit more, or it might be a little bit less.
This results in a static-y pattern, where half of the pixels think there's something slightly closer to the sun than the pixel itself.
This static-y pattern is called "shadow acne", and you don't want that.

The solution: just check if the pixel is "close enough" to `shadowtex0`. Yes, it's really that simple.
In practice, you just need to subtract a tiny number from `shadowPos.z` (or add a tiny number to `shadowtex0`),
so that random fluctuations won't mess it up. This tiny number is called the shadow bias.
This example pack takes things a step farther by picking a shadow bias dynamically,
based on the surface normal and the distortion factor (explained later).
Surfaces which are tangent to the sun vector are more prone to shadow acne than surfaces which are perpendicular.
Likewise, lower resolutions also makes shadow acne more apparent.
As one last catch-all, there's also a global multiplier for the shadow bias, which is configurable in-game.

There is one last problem with shadow bias though: near the corners of blocks,
the offset shadow sample position can sometimes clip through another block,
causing shadows to not appear where they should. This is called peter panning.
Normally the solution to this was to just keep the bias as small as possible.
But there's a better solution available: instead of offsetting the
sample position towards the sun, offset it along the surface normal.
This allows larger shadow biases (which itself comes with less chance of shadow acne),
while avoiding peter panning at the same time. This tutorial includes an option
named `NORMAL_BIAS` which can be used to configure which direction to offset in.

## What is shadow distortion?
Drawing the shadow map means drawing the entire world twice per frame. This means reduced framerates.
One way to increase framerate a bit is to lower the resolution of the shadow map.
The maximum resolution that most graphics cards can handle is 8192x8192.
This is usually a lot bigger than your monitor though,
so a low-end shader pack might use a resolution somewhere between 256x256 and 1024x1024.
By contrast, a 12-chunk view distance will load an area (12 * 2 + 1) * 16 = 400 blocks wide.
Do you spot the problem? A shadow map resolution this small simply doesn't have enough pixels for everything.
Even at noon, every block is between half a pixel and 2 pixels wide.
There's just not enough detail available to make good-looking shadows.
Now, you could increase the resolution, and therefore the lag too,
but even the maximum resolution will only get you up to about 20 pixels per block.
By comparason, if you have your face pressed up against a block in-game,
it could be hundreds or even thousands of pixels wide, depending on your window resolution.

The solution: shadow distortion.
Shadow distortion is the process of making objects bigger near the center of the shadow map, and smaller near the edges.
This means the shadow map acts as if it were higher resolution near the center, and lower resolution near the edges.
Since the shadow map is always centered around the player, this equates to higher resolution shadows near the player.
This is done in 2 parts: shadow.vsh manipulates the size of objects in the shadow map,
and the programs that use the shadow map apply the same manipulations to shadowPos in order to sample it in the correct location.
Shadow distortion won't get you up to perfectly crisp shadow edges, but it's certainly an improvement.

There are other solutions out there as well, like PCSS or CSM, but distortion is the easiest one to wrap your head around.
That's why I used that in this example pack.
It has absolutely nothing to do with the fact that I have no idea how PCSS works.
