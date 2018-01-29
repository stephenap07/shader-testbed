#version 410 core

out vec4 outColor;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;

#define STEPS 255
#define STEP_SIZE 0.0001
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

float sceneSDF(vec3 p)
{
   //float dist = sphereHit(p, vec3(0.0, 0.0, -1.0), 0.55);
   float dist = boxHit(p, vec3(0.1, 0.1, 0.1));
   return dist;
}

float raymarchHit(vec3 position, vec3 direction)
{
	float depth = 0;
   for (int i = 0; i < STEPS; ++i)
   {
      float dist = sceneSDF(position + direction * depth);
      if (dist < STEP_SIZE)
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
        sceneSDF(vec3(p.x + STEP_SIZE, p.y, p.z)) - sceneSDF(vec3(p.x - STEP_SIZE, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + STEP_SIZE, p.z)) - sceneSDF(vec3(p.x, p.y - STEP_SIZE, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + STEP_SIZE)) - sceneSDF(vec3(p.x, p.y, p.z - STEP_SIZE))
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
   cam.origin = vec3(-0.2, 0.20, 0.25);

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
   if (dist > 0.0)
   {
      vec3 n = estimateNormal(r.origin + r.direction * dist);
      outColor = abs(vec4(n.x, n.y, n.z, 1.0));
   }
   else
   {
      float y = 0.5 * (r.direction.y + 1.0);
      vec3 gradient = (1.0 - y) * vec3(1.0, 1.0, 1.0) + y * vec3(0.3, 0.3, 0.8);
      outColor = vec4(gradient, 1.0);
   }
}
