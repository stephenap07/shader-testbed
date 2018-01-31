#version 410 core

out vec4 outColor;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;

#define STEPS 255
#define EPSILON 0.0001
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

float sphereHit(vec3 p, vec3 c, float r)
{
   return distance(p, c) - r;
}

float boxHit(vec3 p, vec3 b)
{
   vec3 d = abs(p) - b;
   return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float udRoundedBox(vec3 p, vec3 b, float r)
{
   return length(max(abs(p)-b, 0.)) -r;
}

float sceneSDF(vec3 p)
{
   float dist = min(
      boxHit(p*2.0, vec3(0.1, 0.2, 0.1)) /2.0,
      sphereHit(p*2.0, vec3(0.0, 0.3 * sin(iTime / 2.0), 0.0), 0.10) /2.0
   );
   return dist;
}

float raymarchHit(vec3 position, vec3 direction)
{
	float depth = 0;
   for (int i = 0; i < STEPS; ++i)
   {
      float dist = sceneSDF(position + direction * depth);
      if (dist < EPSILON)
      {
			return depth;
      }
      depth += dist;
      if (depth >= MAX_DIST)
      {
         return -1.0;
      }
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

void main()
{
   camera cam;
   float fov = radians(60.0); // vertical field of view

   float half_height = tan(fov/2.0);
   float half_width = (16.0/9.0)*half_height;

   float mx = 2.0 * ((iMouse.x / iResolution.x) - half_width);
   float my = 2.0 * ((iMouse.y / iResolution.y) - half_height);

   vec3 look = vec3(0.0, 0.0, 0.0);
   vec3 vup = vec3(0, 1, 0);
   cam.origin = vec3(-0.30*sin(iTime), 0.20, 0.30 * cos(iTime));

   // set up the orthonormal basis
   vec3 w = normalize(cam.origin - look);
   vec3 v = normalize(vup - dot(vup, w) * w);
   vec3 u = cross(v, w);

   // final camera vectors
   cam.left_corner = vec3(half_width, half_height, -1.0);
   cam.left_corner = cam.origin - half_width*u - half_height*v - w;
   cam.horizontal = 2.0*half_width*u;
   cam.vertical = 2.0*half_height*v;

   ray r = get_ray(cam, gl_FragCoord.xy / iResolution);

   float dist = raymarchHit(r.origin, r.direction);

   if (dist > -1.0)
   {
      vec3 p = r.origin + r.direction * dist;
      vec3 n = estimateNormal(p);
      vec3 Kd = n;
      vec3 Ks = vec3(1.0, 1.0, 1.0);
      float m = 10.0;
      vec3 lightPos = vec3(sin(iTime * 2.0), 0.3, -cos(iTime * 2.0));
      vec3 l = normalize(lightPos - look); // assuming look represents object for now
      vec3 v = normalize(r.origin - p);
      vec3 h = normalize(v + lightPos);
      float cosTh = clamp(dot(n, h), 0.0, 1.0);
      float cosTi = clamp(dot(l, n), 0.0, 1.0);
      outColor =  vec4(cosTi * (Kd + pow(cosTh, m) * Ks) * vec3(1.0, 1.0, 1.0), 1.0);
   }
   else
   {
      float y = 0.5 * (r.direction.y + 1.0);
      vec3 gradient = (1.0 - y) * vec3(0.8, 0.8, 0.8) + y * vec3(0.05, 0.05, 0.05);
      outColor = vec4(gradient, 1.0);
   }
}
