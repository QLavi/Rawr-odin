package rt_stuff

import "core:math/linalg"

Emissive :: struct { intensity: f32, }
Lambertian :: struct { ref_factor: f32, }
Dielectric :: struct { ior: f32, }
Metallic :: struct { fuzz_factor: f32, }

Material :: struct {
    color : Vec3,
    mat_type : union {
        Emissive,
        Lambertian,
        Dielectric,
        Metallic,
    },
}

near_zero :: proc(u: Vec3) -> bool
{
    s:f32 = 1e-7
    return (linalg.abs(u.x) < s) && (linalg.abs(u.y) < s) && (linalg.abs(u.z) < s)
}

reflect :: proc(u, n: Vec3) -> Vec3
{
    dir := u - 2 * linalg.dot(u, n) * n
    return dir
}

material_lambert :: proc(record: Record) -> (new_ray: Ray)
{
    new_ray.origin = record.p
    new_ray.dir = record.normal + random_in_unit_sphere()
    if near_zero(new_ray.dir) { new_ray.dir = record.normal }
    return
}

material_metallic :: proc(ray: Ray, record: Record) -> (new_ray: Ray)
{
    fuzz_factor : f32
    #partial switch mat in record.material.mat_type {
        case Metallic:
            fuzz_factor = mat.fuzz_factor
        case:
    }
    fuzz_reflect := fuzz_factor * random_in_unit_sphere()
    bounce_ray := reflect(ray.dir, record.normal)

    new_ray.origin = record.p
    new_ray.dir = bounce_ray + fuzz_reflect
    return
}

material_dielectric :: proc()
{

}
