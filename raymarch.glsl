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

float raymarchHit(vec3 position, vec3 direction)
{
	float depth = 0;
   for (int i = 0; i < STEPS; ++i)
   {
      float dist = boxHit(position + direction * depth, vec3(0.10, 0.10, 0.10));
      //float dist = sphereHit(position + direction * depth, vec3(0.0, 0.0, -1.0), 0.55);
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

void main()
{
   camera cam;
   float fov = radians(60.0); // vertical field of view

   float half_height = tan(fov/2.0);
   float half_width = (16.0/9.0)*half_height;

   float mx = 2.0 * ((iMouse.x / iResolution.x) - half_width);
   float my = 2.0 * ((iMouse.y / iResolution.y) - half_height);

   // set up the orthonormal basis
   vec3 look = vec3(mx, my, -1);
   vec3 vup = vec3(0, 1, 0);
   cam.origin = vec3(0.0, 0.0, 0.3);
   vec3 w = normalize(-look);
   vec3 v = normalize(vup - dot(vup, w) * w);
   vec3 u = cross(v, w);
   cam.left_corner = vec3(half_width, half_height, -1.0);
   cam.left_corner = cam.origin - half_width*u - half_height*v - w;
   cam.horizontal = 2.0*half_width*u;
   cam.vertical = 2.0*half_height*v;

   vec2 uv = gl_FragCoord.xy / iResolution;
   ray r = get_ray(cam, uv);

   float dist = raymarchHit(r.origin, r.direction);
   if (dist > 0.0)
   {
      //vec3 n = normalize((r.origin + r.direction * dist) - vec3(0.0, 0.0, -1.0));
      //outColor = 0.5 * vec4(n.x + 1.0, n.y + 1.0, n.z + 1.0, 1.0);
      outColor = vec4(1.0, 0.0, 0.0, 1.0);
   }
   else
   {
      float y = 0.5 * (r.direction.y + 1.0);
      vec3 gradient = (1.0 - y) * vec3(1.0, 1.0, 1.0) + y * vec3(0.3, 0.3, 0.8);
      outColor = vec4(gradient, 1.0);
   }
}
