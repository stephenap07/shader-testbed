#version 410 core

out vec4 outColor;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform vec4 iColor;
uniform float iShininess = 10.0;

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
      sdfRoundedBox(p * 2.0, vec3(0.2, 0.6, 0.6), 0.05) / 2.0,
      sdfSphere(p, vec3(-0.35, 0.0, -0.3), 0.2) / 2.0
   );
   dist = min(dist, sdfPlane(p, vec4(0.0, 1.0, 0.0, 0.2)));
   return dist;
}

float shadow(in vec3 ro, in vec3 rd, float mint, float maxt, float k)
{
   float res = 1.0;
   for( float t=mint; t < maxt; )
   {
      float h = sceneSDF(ro + rd*t);
      if( h < EPSILON )
         return 0.0;
      res = min(res, k * h / t);
      t += h;
   }
   return res;
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
   cam.origin = vec3(-0.35, 0.30, 0.50);

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
      vec3 lightPos = vec3(-0.1 * sin(iTime), 1.0, 0.6 * cos(iTime));
      vec3 p = r.origin + r.direction * dist;
      vec3 pshadow = r.origin + r.direction * (dist - EPSILON);
      float shadowDist = shadow(lightPos, normalize(pshadow - lightPos), EPSILON, distance(lightPos, pshadow), 8.5);

      vec3 n = estimateNormal(p);
      vec4 Kd = iColor;
      vec3 Ks = vec3(1.0, 1.0, 1.0);
      vec3 l = normalize(lightPos - look); // assuming look represents object for now
      vec3 v = normalize(r.origin - p);
      vec3 h = normalize(v + lightPos);
      float cosTh = clamp(dot(n, h), 0.0, 1.0);
      float cosTi = clamp(dot(l, n), 0.0, 1.0);

      if (shadowDist <= EPSILON / 2.0)
      {
         cosTi = (1.0-shadowDist) * shadowDist;
      }

      outColor = vec4(cosTi * (Kd.xyz + pow(cosTh, iShininess) * Ks) * vec3(1.0, 1.0, 1.0), 1.0);
   }
   else
   {
      float y = 0.5 * (r.direction.y + 1.0);
      vec3 gradient = (1.0 - y) * vec3(0.8, 0.8, 0.8) + y * vec3(0.05, 0.05, 0.05);
      outColor = vec4(gradient, 1.0);
   }
}
