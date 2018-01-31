#pragma once

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include "clock.h"

class single_quad_app
{
public:
   single_quad_app();
   ~single_quad_app();

   bool init();
   void run();
   void destroy();

   void drawQuad();

   int screen_w = 1280.f;
   int screen_h = 720.f;

   double mouse_x = 0;
   double mouse_y = 0;

   GLFWwindow* window;
   ticker system_ticker;
};
