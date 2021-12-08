package rt_stuff

import "core:math"

Image :: struct
{
    data: [^]byte,
    bpp: i32,
    size: [2]i32,
}

load_sphere_uv :: proc(p: Vec3) -> (uv: Vec2)
{
    theta:f32 = math.acos(-p.y)
    phi:f32 = math.atan2(-p.z, p.x) + math.PI

    uv.x = phi / (2.0 * math.PI)
    uv.y = theta / math.PI
    return
}

load_quad_uv :: proc(p, x_, y_: Vec2) -> (uv: Vec2)
{
    uv.x = (p.x - x_[0]) / (x_[1] - x_[0])
    uv.y = (p.y - y_[0]) / (y_[1] - y_[0])
    return
}

load_color_from_uv :: proc(uv: Vec2, image: ^Image) -> (color: Vec3)
{
    color = {1, 0, 1}
    if image.data == nil { return }
    x := clamp(uv.x, 0.0, 1.0)
    y := 1 - clamp(uv.y, 0.0, 1.0)

    width:= image.size.x
    height:= image.size.y
    bpp := image.bpp

    i := i32(x * f32(width))
    j := i32(y * f32(height))

    if i >= width { i = width -1 }
    if j >= height { j = height -1 }

    c_scale :f32 = 1 / 255.0
    offset := j * (width * bpp) + i * bpp
    rgb := image.data[offset:offset+3]

    color.x = c_scale * f32(rgb[0])
    color.y = c_scale * f32(rgb[1])
    color.z = c_scale * f32(rgb[2])
    return
}

