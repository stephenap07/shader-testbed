#version 410 core

out vec4 outColor;

uniform float iElapsedTime;
uniform vec2 iResolution;

struct hit_record
{
    float t;
    vec3 p;
    vec3 normal;
};
    
struct ray
{
    vec3 origin;
    vec3 direction;
};
    
struct sphere
{
    vec3 center;
    float radius;
};

struct camera
{
   vec3 origin;
	vec3 left_corner;
	vec3 horizontal;
	vec3 vertical;
};
    
struct world
{
    sphere sphereArr[2];
};

vec3 ray_point_at_parameter(ray r, float t)
{
    return r.origin + t * r.direction;
}
    
float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

hit_record hit_sphere(sphere sph, ray r, float tmin, float tmax)
{
    hit_record rec;
    rec.t = -1.0;
    vec3 l = sph.center - r.origin;
    float s = dot(l, normalize(r.direction));
    float lsqrd = dot(l, l);
    float rsqrd = sph.radius * sph.radius;
    if (s < 0.0 && lsqrd > rsqrd)
        return rec;
    float msqrd = lsqrd - (s * s);
    if (msqrd > rsqrd)
        return rec;
    float q = sqrt(rsqrd - msqrd);
    float t;
	if (lsqrd > rsqrd)
        t = s - q;
    else
        t = s + q;
    if (t < tmax && t > tmin)
    {
    	rec.t = t;
    	rec.p = ray_point_at_parameter(r, rec.t);
    	rec.normal = (rec.p - sph.center) / sph.radius;
    }
    return rec;
}

hit_record hit_world(world w, ray r)
{
    hit_record rec;
    rec.t = -1.0;
    float closest_so_far = 1000.0;
    for (int i = 0; i < 2; ++i)
    {
        hit_record temp = hit_sphere(w.sphereArr[i], r, 0.0, closest_so_far);
        if (temp.t > 0.0)
        {
            closest_so_far = temp.t;
            rec = temp;
        }
    }
    return rec;
}

ray get_ray(camera cam, vec2 uv)
{   
   	return ray(cam.origin, cam.left_corner + uv.x * cam.horizontal + uv.y * cam.vertical);
}

vec3 random_in_unit_sphere()
{
   vec3 p;
   int i = 0;
   do {
      float randVec1 = rand(gl_FragCoord.xy * i);
      float randVec2 = rand(gl_FragCoord.xy * i - 10.0);
      float randVec3 = rand(gl_FragCoord.xy * i + 10.0);
      p = 2.0 * vec3(randVec1, randVec2, randVec3) - vec3(1.0, 1.0, 1.0);
      ++i;
   } while (length(p)*length(p) >= 1.0);
   return p;
}

vec3 color(world w, ray r, int depth)
{
    hit_record rec = hit_world(w, r);
    if (depth < 50 && rec.t > 0.0)
    {
       vec3 target = rec.p + rec.normal + random_in_unit_sphere();
       vec3 attenuation = vec3(0.8, 0.6, 0.3);
       ray scattered = ray(rec.p, normalize(target - rec.p));
       return attenuation * color(w, scattered, depth + 1);
    }
    else
    {
       vec3 dir = normalize(r.direction);
       float t = 0.5 * (dir.y + 1.0);
       return (1.0 - t) * vec3(1.0, 1.0, 1.0) + t * vec3(0.5, 0.7, 1.0);
    }
}

void main()
{
   int numSamples = 2;

   camera cam;
   cam.origin = vec3(0, 0, 0);
   cam.left_corner = vec3(-2.0, -1.0, -1.0);
   cam.horizontal = vec3(4.0, 0.0, 0.0);
   cam.vertical = vec3(0.0, 2.0, 0.0);

   world w;
   w.sphereArr[0] = sphere(vec3(0, 0, -1), 0.5 * sin(iElapsedTime));
   w.sphereArr[1] = sphere(vec3(0.0, -100.5, -1.0), 100.0);

   vec3 col = vec3(0, 0, 0);

   for (int i = 0; i < numSamples; ++i)
   {
      float u = gl_FragCoord.x + rand(vec2(float(i), float(i) + 10.0));
      float v = gl_FragCoord.y + rand(vec2(float(i), float(i) - 10.0));

      vec2 uv = vec2(u, v) / iResolution;
      ray r = get_ray(cam, uv);
      col += color(w, r, 0);
   }

   col /= float(numSamples);
   col = vec3(sqrt(col.x), sqrt(col.y), sqrt(col.z));

   outColor = vec4(col, 1.0);
}
