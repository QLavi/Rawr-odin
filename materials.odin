package rt_stuff

import "core:math/linalg"
import "core:math/rand"
import "core:math"

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

refract :: proc(u: Vec3, n: Vec3, ratio: f32) -> (bool, Vec3)
{
    u_dot_n :f32 = linalg.dot(u, n)
    discr := 1.0 - (ratio * ratio) * ( 1.0 - (u_dot_n * u_dot_n))

    refracted_ray: Vec3
    refract := true if discr > 0 else false
    if refract {
        refracted_ray = ratio * (u - (u_dot_n * n)) - math.sqrt(discr) * n
    }
    return refract, refracted_ray
}

schlick_approx :: proc(cos, r_ix: f32) -> (res: f32)
{
    r0 := (1.0 - r_ix) / ( 1.0 + r_ix )
    r0 = r0 * r0
    res = r0 + (1 - r0) * math.pow(1 - cos, 5)
    return
}

material_lambert :: proc(record: ^Record) -> (new_ray: Ray)
{
    new_ray.origin = record.p
    new_ray.dir = record.normal + random_in_unit_sphere()
    if near_zero(new_ray.dir) { new_ray.dir = record.normal }
    return
}

material_metallic :: proc(ray: Ray, record: ^Record) -> (new_ray: Ray)
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

material_dielectric :: proc(ray: Ray, record: ^Record) -> (new_ray: Ray)
{
    r_ix: f32
    #partial switch mat in record.material.mat_type {
        case Dielectric:
            r_ix = mat.ior
        case:
    }

    n1_over_n2: f32
    outward_normal: Vec3
    cosine: f32
    d_dot_n := linalg.dot(ray.dir, record.normal)
    if(d_dot_n > 0)
    {
        outward_normal = -record.normal
        n1_over_n2 = r_ix
        cosine = linalg.dot(ray.dir, record.normal)
    }
    else
    {
        outward_normal = record.normal
        n1_over_n2 = 1.0 / r_ix
        cosine = -linalg.dot(ray.dir, record.normal)
    }

    reflected_ray := reflect(ray.dir, record.normal)
    refract, refracted_ray := refract(ray.dir, outward_normal, n1_over_n2)
    reflect_prob := schlick_approx(cosine, r_ix) if refract else 1.0

    if rand.float32_range(0, 1) < reflect_prob
    {
        new_ray = Ray {record.p, reflected_ray}
    }
    else
    {
        new_ray = Ray {record.p, refracted_ray}
    }
    return
}
