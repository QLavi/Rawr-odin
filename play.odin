package rt_stuff

import "core:strings"
import "core:math/linalg"
import "core:math/rand"
import "core:math"
import stbi "vendor:stb/image"

Vec3 :: distinct [3]f32
Vec2 :: distinct [2]f32

Ray :: struct {
    origin : Vec3,
    dir : Vec3,
}

Record :: struct {
    t: f32,
    p: Vec3,
    uv: Vec2,
    normal: Vec3,
    material : Material,
}

main :: proc()
{
    aspect : f32 = 16.0 / 9.0
    bpp    : i32 = 4
    width  := i32(1980 * 0.7)
    height := i32(f32(width) / aspect)

    max_depth: i32 = 16
    max_samples: i32 = 5

    fov := 45.0
    theta := (math.PI / 180) * fov
    half_height := f32(math.tan(theta / 2.0))
    half_width := aspect * half_height

    look_from := Vec3 {0, 10, -10}
    look_at := Vec3 {0, 0, 0}
    up := Vec3 {0, 1, 0}

    view_z := linalg.normalize(look_from - look_at)
    view_u := linalg.normalize(linalg.cross(up, view_z))
    view_v := linalg.cross(view_z, view_u)

    lower_left_corner := -half_width * view_u - half_height * view_v - view_z
    horizontal := 2.0 * half_width * view_u
    vertical := 2.0 * half_height * view_v

    spheres := make([]Sphere, 3)
    defer delete(spheres)

    checker := load_texture_from_file("data/checker.png")
    defer stbi.image_free(checker.data)

    metallic_default := Metallic{0.0}
    lambert_default := Lambertian {0.5}
    emissive_default := Emissive {4}
    dielectric_default := Dielectric {1.45}

    spheres[0] = Sphere { 0.8, Vec3{ 0, 0.8, 0}, Material{ Vec3{0.7, 0.5, 1.0}, lambert_default}, nil}

    quads := make([]Quad, 1)
    defer delete(quads)

    quads[0] = Quad { Vec3{0, 0, 0}, Vec2{10, 10}, Material{ Vec3{0.5, 0.5, 0.5}, lambert_default }, nil}

    image_buf := make([]byte, width * height * bpp)
    defer delete(image_buf)

    ix: i32 = 0
    for y:i32 = height -1; y >= 0; y -=1 
    {
        for x:i32 = 0; x < width; x +=1
        {
            color := Vec3{}
            for i in 0..< max_samples 
            {
                u := (f32(x) + (rand.float32_range(0, 0.98))) / f32(width -1)
                v := (f32(y) + (rand.float32_range(0, 0.98))) / f32(height -1)

                ray_dir := lower_left_corner + u * horizontal + v * vertical
                ray := Ray { look_from, ray_dir }

                ray.dir = linalg.normalize(ray.dir)
                color = color + trace_ray(ray, max_depth, spheres, quads)
            }
            write_image_color(color, image_buf, &ix, max_samples)
        }
    }
    write_image("render.png", width, height, bpp, raw_data(image_buf))
}

scene_hit :: proc(ray: Ray, spheres: []Sphere, quads: []Quad) -> (hit_anything: bool, record: Record)
{
    hit_anything = false
    t_in := Vec2{0.001, 1000};

    for i in 0..< len(spheres) {
        hit, tmp_record := sphere_hit(ray, &spheres[i], t_in)

        if hit {
            t_in[1] = tmp_record.t 
            hit_anything = true
            record = tmp_record
        }
    }

    for i in 0..< len(quads) {
        hit, tmp_record := quad_xz_hit(ray, &quads[i], t_in)

        if hit {
            t_in[1] = tmp_record.t
            hit_anything = true
            record = tmp_record
        }
    }

    return 
}

trace_ray :: proc(ray: Ray, max_depth: i32, spheres: []Sphere, quads: []Quad) -> (color: Vec3)
{
    color = {0.5, 0.7, 1.0}
    if max_depth <= 0 { return }

    hit, record := scene_hit(ray, spheres, quads)

    if hit
    {
        switch mat in record.material.mat_type
        {
            case Lambertian: {
                new_ray := material_lambert(&record)
                color = record.material.color * trace_ray(new_ray, max_depth -1, spheres, quads)
            }
            case Metallic: {
                new_ray := material_metallic(ray, &record)

                if linalg.dot(new_ray.dir, record.normal) > 0
                { color = record.material.color * trace_ray(new_ray, max_depth -1, spheres, quads) }
                else { color = {4, 4, 4} }
            }
            case Emissive: {
                new_ray := Ray { record.p, record.normal + random_in_unit_sphere() }
                color = mat.intensity + record.material.color * trace_ray(ray, max_depth -1, spheres, quads)
            }
            case Dielectric: {
                new_ray := material_dielectric(ray, &record)
                color = Vec3{1, 1, 1} * trace_ray(new_ray, max_depth -1, spheres, quads)
            }
        }
    }
    else { return }

    return
}

random_in_unit_sphere :: proc() -> (p : Vec3)
{
    for {
        p = Vec3{
            rand.float32_range(-1, 1),
            rand.float32_range(-1, 1),
            rand.float32_range(-1, 1),
        }
        if linalg.dot(p, p) >= 1.0 { continue }
        return 
    }
}

load_texture_from_file :: proc(filename: string) -> (image: Image)
{
    name := strings.clone_to_cstring(filename)

    image.data = stbi.load(name, &image.size[0], &image.size[1], &image.bpp, 0)
    return
}

write_image_color :: proc(color: Vec3, image: []byte, ix: ^i32, max_samples: i32)
{
    scale := 1 / f32(max_samples)
    r := math.sqrt(color[0] * scale)
    g := math.sqrt(color[1] * scale)
    b := math.sqrt(color[2] * scale)

    image[ix^] = u8(clamp(r, 0, 0.999) * 256)
    ix^ += 1
    image[ix^] = u8(clamp(g, 0, 0.999) * 256)
    ix^ += 1
    image[ix^] = u8(clamp(b, 0, 0.999) * 256)
    ix^ += 1
    image[ix^] = 255
    ix^ += 1
}

write_image :: proc(filename: string, width, height, bpp: i32, image_ptr: rawptr)
{
    image_name:= strings.clone_to_cstring(filename)
    _ = stbi.write_png(image_name, width, height, bpp, image_ptr, width * bpp)
}
