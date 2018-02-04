#version 410 core

out vec4 outColor;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform vec4 iColor;
uniform float iShininess = 10.0;

#define STEPS 255
#define EPSILON 0.001
#define MAX_DIST 100.0

struct camera
{
   vec3 origin;
   vec3 left_corner;
   vec3 horizontal;
   vec3 vertical;
};

struct ray
{
   vec3 origin;
   vec3 direction;
};
    
ray get_ray(camera cam, vec2 uv)
{   
   return ray(cam.origin, normalize(cam.left_corner + uv.x * cam.horizontal + uv.y * cam.vertical));
}

float sdfSphere(vec3 p, vec3 c, float r)
{
   return distance(p, c) - r;
}

float sdfBox(vec3 p, vec3 b)
{
   vec3 d = abs(p) - b;
   return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdfRoundedBox(vec3 p, vec3 b, float r)
{
   return length(max(abs(p)-b, 0.)) -r;
}

float sdfPlane(vec3 p, vec4 n)
{
   // n must be normalized
   return dot(p, n.xyz) + n.w;
}

vec3 repeat(vec3 p, int repeat)
{
   return mod(p, repeat) - 0.5 * repeat;
}

float sceneSDF(vec3 p)
{
   float dist = min(
      sdfRoundedBox(p, vec3(0.2, 0.4, 0.2), 0.04),
      sdfSphere(p, vec3(-0.35, 0.1, -0.3), 0.2) / 2.0
   );
   dist = min(dist, sdfPlane(p, vec4(0.0, 1.0, 0.0, 0.2)));
   return dist;
}

float shadow(in vec3 ro, in vec3 rd, float mint, float maxt, float k)
{
   float res = 1.0;
   for (float t = mint; t < maxt;)
   {
      float dist = sceneSDF(ro + rd * t);
      res = min(res, k * dist / t);
      if (dist < EPSILON)
         break;
      t += dist;
   }
   return clamp(res, 0.0, 1.0);
}

float raymarch(vec3 position, vec3 direction)
{
   float depth = 0;
   for (int i = 0; i < STEPS; ++i)
   {
      float dist = sceneSDF(position + direction * depth);
      if (dist < EPSILON)
         return depth;
      depth += dist;
      if (depth >= MAX_DIST)
         return -1.0;
   }
   return -1.0;
}

// Using the gradient of the SDF, estimate the normal on the surface at point p.
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

vec4 computeLight(ray r, float dist)
{
   vec3 lightPos = vec3(-0.3, 1.0, -0.6);
   vec4 lightColor = vec4(1.0, 1.0, 1.0, 1.0);

   vec3 p = r.origin + r.direction * dist;

   vec4 Kd = iColor;
   vec4 Ks = vec4(1.0, 1.0, 1.0, 1.0);

   vec3 n = estimateNormal(p);
   vec3 l = normalize(lightPos - p);
   vec3 v = normalize(r.origin - p);
   vec3 h = normalize(v + lightPos);

   float cosTh = clamp(dot(h, n), 0.0, 1.0);
   float cosTi = clamp(dot(l, n), 0.0, 1.0) * shadow(p, l, 10.0 * EPSILON, distance(p, lightPos), 4.0);

   return (Kd + Ks * pow(cosTh, iShininess)) * lightColor * cosTi;
}

camera getCam(vec3 origin, vec3 look, vec3 vup, float fov)
{
   camera cam;
   cam.origin = origin;

   fov = radians(fov); // vertical field of view
   float half_height = tan(fov / 2.0);
   float half_width = (iResolution.x / iResolution.y) * half_height;

   float mx = 2.0 * ((iMouse.x / iResolution.x) - half_width);
   float my = 2.0 * ((iMouse.y / iResolution.y) - half_height);

   // set up the orthonormal basis
   vec3 w = normalize(cam.origin - look);
   vec3 v = normalize(vup - dot(vup, w) * w);
   vec3 u = cross(v, w);

   // final camera vectors
   cam.left_corner = vec3(half_width, half_height, -1.0);
   cam.left_corner = cam.origin - half_width*u - half_height*v - w;
   cam.horizontal = 2.0*half_width*u;
   cam.vertical = 2.0*half_height*v;

   return cam;
}

void main()
{
   vec3 origin = vec3(-0.40, 0.55, 0.35);
   vec3 look = vec3(0.0, 0.0, 0.0);
   vec3 vup = vec3(0, 1, 0);
   camera cam = getCam(origin, look, vup, 60.0);
   ray r = get_ray(cam, gl_FragCoord.xy / iResolution);
   float dist = raymarch(r.origin, r.direction);

   if (dist > -1.0)
   {
      outColor = computeLight(r, dist);
   }
   else
   {
      float y = 0.5 * (r.direction.y + 1.0);
      vec3 gradient = (1.0 - y) * vec3(0.8, 0.8, 0.8) + y * vec3(0.05, 0.05, 0.05);
      outColor = vec4(gradient, 1.0);
   }
}
