// ------------------------------------------------------------------ a cliff's face: gneiss
// Creel draws high ground's faces with its "cliff" shader, coursed earth and stone. Smyana's cliffs are the Rhodopes'
// gneiss (D-032, D-033): thin beds that dip, long along the face, each with a lit top edge and a shadow under it,
// broken by upright joints, moss on the lip, a fallen leaf caught on a ledge here and there, darker toward the foot.
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
        float level_px = 20.0;
        float rim = iinfo.x;
        float foot = iinfo.z;
        float side = iinfo.y;
        float bay = bayer(ivec2(gl_FragCoord.xy / art_px));
        // (in art px: along the face, and down from the rim)
        vec2 p = floor(vec2(iface.x * 35.8 * 1.5 + side * 300.0, (rim - iface.y) * level_px * 1.5));
        float depth = max((rim - foot) * level_px * 1.5, 1.0);
        float k = clamp(p.y / depth, 0.0, 1.0);
        // the beds: 3 to 6 px thick, dipping along the face, waving a little
        float hw = p.y + p.x * 0.17 + (vnoise(vec2(p.x * 0.03, 3.0)) - 0.5) * 9.0;
        float course = floor(hw / 4.5);
        float cy = fract(hw / 4.5);
        float off = hash(vec2(course, 7.0)) * 61.0;
        float bw = 22.0 + 40.0 * hash(vec2(course, 3.0));
        float bx = floor((p.x + off) / bw);
        float fx = fract((p.x + off) / bw);
        float tone = floor(hash(vec2(bx, course)) * 4.0) / 3.0;
        vec3 col = mix(vec3(0.44, 0.42, 0.38), vec3(0.69, 0.65, 0.57), tone);
        // (a warm rusty bed now and then, and a recessed one in shadow)
        if (hash(vec2(course, 11.0)) > 0.82) col *= vec3(1.08, 0.96, 0.82);
        if (hash(vec2(course, 13.0)) > 0.8) col *= 0.74;
        if (cy < 0.24) col *= 1.14;                                       // a bed's lit top edge
        else if (cy > 0.76) col *= 0.66;                                  // the shadow under it
        if (fx * bw < 1.0 && hash(vec2(bx, course + 9.0)) > 0.3) col *= 0.55;  // a joint
        // upright cracks through many beds
        float crack = floor((p.x + 13.0) / 37.0);
        float cxp = mod(p.x + 13.0, 37.0) - 18.0 - floor((hash(vec2(crack, floor(p.y / 9.0))) - 0.5) * 3.0);
        if (cxp == 0.0 && hash(vec2(crack, 5.0)) > 0.4 && p.y > hash(vec2(crack, 6.0)) * depth * 0.5) col *= 0.5;
        // moss in patches on the beds' tops, a leaf caught on a ledge
        if (vnoise(p * 0.09 + 40.0) > 0.7 && cy < 0.5 && hash(p) > 0.35) col = mix(col, vec3(0.34, 0.42, 0.19), 0.7);
        if (cy < 0.24 && hash(p + 17.0) > 0.975) col = hash(p + 3.0) > 0.5 ? vec3(0.80, 0.50, 0.14) : vec3(0.62, 0.30, 0.10);
        // the lip: the ground's own cover hanging over the edge
        float lip = 2.0 + floor(3.0 * vnoise(vec2(p.x * 0.3, 2.0))) + (hash(vec2(p.x, 5.0)) > 0.8 ? 2.0 : 0.0);
        if (p.y < lip) {
            col = hash(vec2(p.x, 8.0)) > 0.5 ? vec3(0.36, 0.42, 0.19) : vec3(0.46, 0.50, 0.23);
            if (p.y < 1.0) col *= 1.15;
        } else if (p.y < lip + 2.0) {
            col *= 0.55;
        }
        col *= side > 0.5 ? 1.0 : 0.7;                                    // (the face turned from the sun)
        col *= mix(1.0, 0.62, floor(clamp(k + bay * 0.2, 0.0, 0.999) * 4.0) / 3.0);
        // scree at the foot
        float scree = 3.0 + floor(4.0 * vnoise(vec2(p.x * 0.25, 9.0)));
        if (depth - p.y < scree && hash(p + 31.0) > 0.45) col = mix(col, vec3(0.40, 0.38, 0.33), 0.7);
        if (depth - p.y < 2.0) col *= 0.55;
        frag_color = vec4(col, 1.0);
"""
