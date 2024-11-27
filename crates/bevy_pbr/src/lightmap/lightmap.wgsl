#define_import_path bevy_pbr::lightmap

#import bevy_pbr::mesh_bindings::mesh

@group(1) @binding(4) var lightmaps_texture: texture_2d<f32>;
@group(1) @binding(5) var lightmaps_sampler: sampler;

// Samples the lightmap, if any, and returns indirect illumination from it.
fn lightmap(uv: vec2<f32>, exposure: f32, instance_index: u32) -> vec3<f32> {
    let packed_uv_rect = mesh[instance_index].lightmap_uv_rect;
    let uv_rect = vec4<f32>(vec4<u32>(
        packed_uv_rect.x & 0xffffu,
        packed_uv_rect.x >> 16u,
        packed_uv_rect.y & 0xffffu,
        packed_uv_rect.y >> 16u)) / 65535.0;

    let lightmap_uv = mix(uv_rect.xy, uv_rect.zw, uv);

    // Mipmapping lightmaps is usually a bad idea due to leaking across UV
    // islands, so there's no harm in using mip level 0 and it lets us avoid
    // control flow uniformity problems.
    //
    // TODO(pcwalton): Consider bicubic filtering.
    // return textureSampleLevel(
    //     lightmaps_texture,
    //     lightmaps_sampler,
    //     lightmap_uv,
    //     0.0).rgb * exposure;
    return textureSampleBicubic(
        lightmaps_texture,
        lightmaps_sampler,
        lightmap_uv).rgb * exposure;
}

fn cubic(v: f32) -> vec4<f32> {
    let n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    let s = n * n * n;
    let x = s.x;
    let y = s.y - 4.0 * s.x;
    let z = s.z - 4.0 * s.y + 6.0 * s.x;
    let w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

fn textureSampleBicubic(tex: texture_2d<f32>, tex_sampler: sampler, orig_texCoords: vec2<f32>) -> vec4<f32> {
    let texture_size = vec2<f32>(textureDimensions(tex).xy);

    let invTexSize = 1.0 / texture_size;

    var texCoords = orig_texCoords * texture_size - 0.5;

    let fxy = fract(texCoords);
    texCoords = texCoords - fxy;

    let xcubic = cubic(fxy.x);
    let ycubic = cubic(fxy.y);

    let c = texCoords.xxyy + vec2(-0.5, 1.5).xyxy;

    let s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    var offset = c + vec4(xcubic.yw, ycubic.yw) / s;

    offset = offset * invTexSize.xxyy;

    let sample0 = textureSample(tex, tex_sampler, offset.xz);
    let sample1 = textureSample(tex, tex_sampler, offset.yz);
    let sample2 = textureSample(tex, tex_sampler, offset.xw);
    let sample3 = textureSample(tex, tex_sampler, offset.yw);

    let sx = s.x / (s.x + s.y);
    let sy = s.z / (s.z + s.w);

    return mix(mix(sample3, sample2, vec4(sx)), mix(sample1, sample0, vec4(sx)), vec4(sy));
}
