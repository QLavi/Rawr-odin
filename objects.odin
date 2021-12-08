package rt_stuff

import "core:math/linalg"
import "core:math"

Sphere :: struct {
    rad : f32,
    position : Vec3,
    material : Material,
}

Quad :: struct {
    position : Vec3,
    size : Vec2,
    material : Material,
}

set_face_normal :: proc(p: Vec3, n: Vec3) -> (new_n: Vec3)
{
    front_face := linalg.dot(p, n) < 0
    if front_face { return n }
    else { return -n }

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
    record.normal = set_face_normal(ray.dir, record.normal)
    record.material = sphere.material

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
    record.normal = set_face_normal(ray.dir, tmp_normal)
    record.material = quad.material

    return
}
