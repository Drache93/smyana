// ------------------------------------------------------------------ a cliff's face: gneiss
// Creel draws high ground's faces with its "cliff" shader, coursed earth and stone. Smyana's cliffs are the Rhodopes'
// gneiss (D-032, D-033): massive rock in a few close tones, split by wandering fractures, its grain as broken dipping
// lines, a ledge now and then, moss on the lip and where water seeps, darker toward the foot. (The first try was thin
// regular beds with joints; Dominic: "The cliff are bricks?")
// Same name, loaded after Creel's, so it takes its place. The helpers are Creel's own (the head of TERRAIN_SHADERS).

def cliff_shaders() -> string:
    return substring(TERRAIN_SHADERS, 0, find_string(TERRAIN_SHADERS, "SHADER terrain")) + """SHADER cliff
    VERTEX
        INPUTS apos:4 atc:2 acolor:4
        UNIFORMS mvp
        gl_Position = mvp * apos;
        iface = atc;
        iinfo = vec4(acolor.r * 9.0, acolor.g, acolor.b * 9.0, 0.0);   // the rim's height, which way it faces, the foot's height
    PIXEL
        INPUTS iface:2 iinfo:4
        UNIFORM float art_px
        UNIFORM float level_px
        float rim = iinfo.x;
        float foot = iinfo.z;
        float side = iinfo.y;
        float bay = bayer(ivec2(gl_FragCoord.xy / art_px));
        // (in art px: along the face, and down from the rim)
        vec2 p = floor(vec2(iface.x * 35.8 * 1.5 + side * 300.0, (rim - iface.y) * level_px * 1.5));
        float depth = max((rim - foot) * level_px * 1.5, 1.0);
        float k = clamp(p.y / depth, 0.0, 1.0);
        // Massive rock, not masonry: broad patches of a few close tones, split into uneven upright blocks by
        // fractures that wander, with the gneiss' grain as broken dipping lines and a ledge now and then.
        // (a fracture leans and wanders all the way down: no two run alike, and none is upright)
        float lane = floor(p.x / 130.0);
        float fxw = p.x + floor((vnoise(vec2(p.y * 0.022, 5.0 + lane)) - 0.5) * 70.0 + (vnoise(vec2(p.y * 0.11, 9.0 + lane)) - 0.5) * 10.0 + p.y * (hash(vec2(lane, 6.0)) - 0.5) * 0.5);
        float block = floor(fxw / 130.0);
        float v = vnoise(p * vec2(0.018, 0.04)) * 0.55 + vnoise(p * vec2(0.06, 0.1) + 7.0) * 0.3 + (hash(vec2(block, 1.0)) - 0.5) * 0.16 + bay * 0.08 + 0.1;
        vec3 col = ramp4(vec3(0.40, 0.385, 0.36), vec3(0.50, 0.48, 0.44), vec3(0.59, 0.565, 0.51), vec3(0.68, 0.645, 0.57), v);
        // (warm rusty stains in places)
        if (vnoise(p * vec2(0.03, 0.02) + 21.0) > 0.7) col *= vec3(1.07, 0.97, 0.84);
        // the grain: thin lines that dip along the face, broken, unevenly spaced
        float hw = p.y + p.x * 0.24 + (vnoise(vec2(p.x * 0.02, 3.0)) - 0.5) * 16.0;
        float grain = vnoise(vec2(hw * 0.45, p.x * 0.01));
        if (abs(grain - 0.5) < 0.035 && vnoise(p * 0.045 + 9.0) > 0.42) col *= 0.74;
        // a ledge: its shadow, and its lit top above that
        float lg = fract(hw / 43.0 + hash(vec2(block, 4.0)));
        if (hash(vec2(block, floor(hw / 43.0 + hash(vec2(block, 4.0))))) > 0.35) {
            if (lg < 0.07) col *= 1.13;
            else if (lg < 0.16) col *= 0.62;
        }
        // the fractures between blocks, and a few that stop short
        float fr = fract(fxw / 130.0) * 130.0;
        if (fr < 1.5 && hash(vec2(block, 12.0)) > 0.25 && vnoise(vec2(p.y * 0.03, block)) > 0.3) col *= 0.52;
        float f2 = floor(fxw / 19.0);
        if (floor(mod(fxw, 19.0)) == floor(hash(vec2(f2, 3.0)) * 19.0) && hash(vec2(f2, floor(p.y / 31.0))) > 0.72) col *= 0.66;
        // moss where water seeps, a leaf caught on a ledge
        if (vnoise(p * 0.07 + 40.0) > 0.72 && hash(p) > 0.4) col = mix(col, vec3(0.33, 0.40, 0.19), 0.65);
        if (lg < 0.07 && hash(p + 17.0) > 0.97) col = hash(p + 3.0) > 0.5 ? vec3(0.80, 0.50, 0.14) : vec3(0.62, 0.30, 0.10);
        // the lip: the ground's own cover hanging over the edge
        float lip = 2.0 + floor(3.0 * vnoise(vec2(p.x * 0.3, 2.0))) + (hash(vec2(p.x, 5.0)) > 0.8 ? 2.0 : 0.0);
        if (p.y < lip) {
            col = hash(vec2(p.x, 8.0)) > 0.5 ? vec3(0.36, 0.42, 0.19) : vec3(0.46, 0.50, 0.23);
            if (p.y < 1.0) col *= 1.15;
        } else if (p.y < lip + 2.0) {
            col *= 0.55;
        }
        col *= side > 0.5 ? 1.0 : 0.7;                                    // (the face turned from the sun)
        col *= mix(1.0, 0.7, floor(clamp(k + bay * 0.2, 0.0, 0.999) * 4.0) / 3.0);
        // scree at the foot
        float scree = 3.0 + floor(4.0 * vnoise(vec2(p.x * 0.25, 9.0)));
        if (depth - p.y < scree && hash(p + 31.0) > 0.45) col = mix(col, vec3(0.40, 0.38, 0.33), 0.7);
        if (depth - p.y < 2.0) col *= 0.55;
        frag_color = vec4(col, 1.0);
"""
