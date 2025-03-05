// assets/shaders/white_shader.glsl
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Sample the texture to preserve the alpha value
    vec4 pixel = Texel(texture, texture_coords);
    // Return a white color with the original alpha multiplied by the current color's alpha
    return vec4(1.0, 1.0, 1.0, pixel.a * color.a);
}