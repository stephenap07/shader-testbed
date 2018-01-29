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

   GLfloat screen_w = 1280.f;
   GLfloat screen_h = 720.f;

   GLFWwindow* window;
   GLuint vao;
   GLuint vbo;
   GLint pos_attrib;
   GLuint program;
   GLuint vert_shader;
   GLuint frag_shader;

   GLint elapsed_time_uniform;
   GLint resolution_uniform;
   GLint mouse_uniform;
   ticker system_ticker;
};