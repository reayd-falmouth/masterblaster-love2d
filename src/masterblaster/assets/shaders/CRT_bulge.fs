#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
    #define HIGHP highp
#else
    #define HIGHP mediump
#endif

extern HIGHP number time;
extern HIGHP vec2 resolution;
extern HIGHP number distortion_fac;
extern HIGHP number feather_fac;
extern HIGHP number noise_fac;
extern HIGHP number scanline_intensity;
extern HIGHP number bloom_fac;

#define BUFF 0.01

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc)
{
    // Recenter Texture Coordinates
    tc = tc * 2.0 - vec2(1.0);

    // Apply Bulge Effect
    tc += (tc.yx * tc.yx) * tc * (distortion_fac - 1.0);

    // Smooth Edge Transition (Feathering)
    HIGHP number mask = (1.0 - smoothstep(1.0 - feather_fac, 1.0, abs(tc.x) - BUFF))
                      * (1.0 - smoothstep(1.0 - feather_fac, 1.0, abs(tc.y) - BUFF));

    // Undo Recenter
    tc = (tc + vec2(1.0)) / 2.0;

    // Fetch Texture Color
    vec4 texColor = Texel(tex, tc);

    // Scanlines
    float scanline = 1.0 - scanline_intensity * sin(pc.y * resolution.y * 0.5);
    texColor.rgb *= scanline;

    // Noise Flicker
    float noise = noise_fac * (fract(sin(dot(pc.xy, vec2(12.9898, 78.233))) * 43758.5453));
    texColor.rgb += noise;

    // Bloom Effect
    vec4 bloom = vec4(texColor.rgb * bloom_fac, 1.0);
    texColor += bloom;

    // Apply Feather Mask
    texColor.rgb *= mask;

    return texColor * color;
}
