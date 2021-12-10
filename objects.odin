package rt_stuff

import "core:math/linalg"
import "core:math"

Sphere :: struct {
    rad : f32,
    position : Vec3,
    material : Material,
    texture : ^Image,
}

Quad :: struct {
    position : Vec3,
    size : Vec2,
    material : Material,
    texture : ^Image,
}

set_quad_normal :: proc(dir, n: Vec3) -> Vec3
{
    d_dot_n := linalg.dot(dir, n)
    n := -n if d_dot_n > 0 else n
    return n
}

sphere_hit :: proc(ray: Ray, sphere: ^Sphere, t_in: Vec2) -> (hit: bool, record: Record)
{
    hit = false
    record = Record{}

    oc := ray.origin - sphere.position
    a: f32 = linalg.dot(ray.dir, ray.dir)
    hb:f32 = linalg.dot(oc, ray.dir)
    c: f32 = linalg.dot(oc, oc) - sphere.rad * sphere.rad

    discr: f32 = hb * hb - a * c
    if discr < 0 { return }

    t: f32 = (-hb - math.sqrt(discr)) / a
    if t < t_in[0] || t > t_in[1]
    {
        t = (-hb + math.sqrt(discr)) / a
        if t < t_in[0] || t > t_in[1] { return }
    }

    hit = true
    record.t = t
    record.p = ray.origin + t * ray.dir

    record.normal = (record.p - sphere.position) / sphere.rad
    record.uv = load_sphere_uv(record.normal)

    color: Vec3
    if sphere.texture != nil
    {
        color = load_color_from_uv(record.uv, sphere.texture)
        record.material.color = color
        record.material.mat_type = sphere.material.mat_type
    }
    else { record.material = sphere.material }

    return
}

quad_xy_hit :: proc(ray: Ray, quad: ^Quad, t_in: Vec2) -> (hit: bool, record: Record)
{
    hit = false
    record = Record{}
    tmp_normal:= Vec3{ 0, 0, 1 }

    n_dot_d := linalg.dot(ray.dir, tmp_normal)
    t := linalg.dot(quad.position - ray.origin, tmp_normal) * (1 / n_dot_d)
    if t < t_in[0] || t > t_in[1] { return }

    x_min := quad.position.x - quad.size[0] / 2.0
    x_max := quad.position.x + quad.size[0] / 2.0

    y_min := quad.position.y - quad.size[1] / 2.0
    y_max := quad.position.y + quad.size[1] / 2.0

    p: Vec3 = ray.origin + t * ray.dir
    if p.x < x_min || p.x > x_max || p.y < y_min || p.y > y_max { return }

    hit = true
    record.t = t
    record.p = p
    record.normal = set_quad_normal(ray.dir, tmp_normal)
    record.uv = load_quad_uv(Vec2{p.x, p.y}, Vec2{x_min, x_max}, Vec2{y_min, y_max})

    color: Vec3
    if quad.texture != nil
    {
        color = load_color_from_uv(record.uv, quad.texture)
        record.material.color = color
        record.material.mat_type = quad.material.mat_type
    }
    else { record.material = quad.material }

    return
}

quad_yz_hit :: proc(ray: Ray, quad: ^Quad, t_in: Vec2) -> (hit: bool, record: Record)
{
    hit = false
    record = Record{}
    tmp_normal:= Vec3{ 1, 0, 0 }

    n_dot_d := linalg.dot(ray.dir, tmp_normal)
    t := linalg.dot(quad.position - ray.origin, tmp_normal) * (1 / n_dot_d)
    if t < t_in[0] || t > t_in[1] { return }

    y_min := quad.position.y - quad.size[0] / 2.0
    y_max := quad.position.y + quad.size[0] / 2.0

    z_min := quad.position.z - quad.size[1] / 2.0
    z_max := quad.position.z + quad.size[1] / 2.0

    p: Vec3 = ray.origin + t * ray.dir
    if p.y < y_min || p.y > y_max || p.z < z_min || p.z > z_max { return }

    hit = true
    record.t = t
    record.p = p
    record.normal = set_quad_normal(ray.dir, tmp_normal)
    record.uv = load_quad_uv(Vec2{p.y, p.z}, Vec2{y_min, y_max}, Vec2{z_min, z_max})

    color: Vec3
    if quad.texture != nil
    {
        color = load_color_from_uv(record.uv, quad.texture)
        record.material.color = color
        record.material.mat_type = quad.material.mat_type
    }
    else { record.material = quad.material }

    return
}

quad_xz_hit :: proc(ray: Ray, quad: ^Quad, t_in: Vec2) -> (hit: bool, record: Record)
{
    hit = false
    record = Record{}
    tmp_normal:= Vec3{ 0, 1, 0 }

    n_dot_d := linalg.dot(ray.dir, tmp_normal)
    t := linalg.dot(quad.position - ray.origin, tmp_normal) * (1 / n_dot_d)
    if t < t_in[0] || t > t_in[1] { return }

    x_min := quad.position.x - quad.size[0] / 2.0
    x_max := quad.position.x + quad.size[0] / 2.0

    z_min := quad.position.z - quad.size[1] / 2.0
    z_max := quad.position.z + quad.size[1] / 2.0

    p: Vec3 = ray.origin + t * ray.dir
    if p.x < x_min || p.x > x_max || p.z < z_min || p.z > z_max { return }

    hit = true
    record.t = t
    record.p = p
    record.normal = set_quad_normal(ray.dir, tmp_normal)
    record.uv = load_quad_uv(Vec2{p.x, p.z}, Vec2{x_min, x_max}, Vec2{z_min, z_max})

    color: Vec3
    if quad.texture != nil
    {
        color = load_color_from_uv(record.uv, quad.texture)
        record.material.color = color
        record.material.mat_type = quad.material.mat_type
    }
    else { record.material = quad.material }

    return
}
