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

   float screen_w = 1280.f;
   float screen_h = 720.f;

   GLFWwindow* window;
   ticker system_ticker;
};