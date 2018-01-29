#include "single_quad_app.h"

#include <stdio.h>
#include <stdlib.h>

#include <chrono>
#include <thread>

#include "clock.h"
#include "opengl_util.h"

// clang-format off
static const GLfloat vertices[] = {
   //  Position  
   -1.0f, -1.0f, // Top-left
   -1.0f,  1.0f, // Bottom-left
    1.0f,  1.0f, // Bottom-right
    1.0f,  1.0f, // Bottom-right
    1.0f, -1.0f, // Top-right
   -1.0f, -1.0f, // Top-left
};
// clang-format on

static void error_callback(int error, const char* description)
{
   fprintf(stderr, "Error: %s\n", description);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
   if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
      glfwSetWindowShouldClose(window, GLFW_TRUE);
}

single_quad_app::single_quad_app()
{
}

single_quad_app::~single_quad_app()
{
}

bool single_quad_app::init()
{
   glfwSetErrorCallback(error_callback);

   if (!glfwInit())
      exit(EXIT_FAILURE);

   glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
   glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
   glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
   glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

   window = glfwCreateWindow(int(screen_w), int(screen_h), "SDF", nullptr, nullptr);

   if (!window)
   {
      fprintf(stderr, "Failed to initialize GLFW3\n");
      return false;
   }

   glfwSetKeyCallback(window, key_callback);

   glfwMakeContextCurrent(window);
   glewExperimental = GL_TRUE;
   glewInit();
   glfwSwapInterval(1);

   glGenVertexArrays(1, &vao);
   glBindVertexArray(vao);

   glGenBuffers(1, &vbo);
   glBindBuffer(GL_ARRAY_BUFFER, vbo);
   glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

   program = glCreateProgram();
   vert_shader = compile_shader_from_file(GL_VERTEX_SHADER, "vertex.glsl");
   frag_shader = compile_shader_from_file(GL_FRAGMENT_SHADER, "raymarch.glsl");
   if (!vert_shader || !frag_shader)
   {
      fprintf(stderr, "Failed to load shaders\n");
      return false;
   }
   glAttachShader(program, vert_shader);
   glAttachShader(program, frag_shader);
   glLinkProgram(program);
   glDeleteShader(vert_shader);
   glDeleteShader(frag_shader);

   glUseProgram(program);
   pos_attrib = glGetAttribLocation(program, "position");
   glVertexAttribPointer(pos_attrib, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), (void*)0);
   glEnableVertexAttribArray(pos_attrib);

   elapsed_time_uniform = glGetUniformLocation(program, "iTime");
   resolution_uniform = glGetUniformLocation(program, "iResolution");
   mouse_uniform = glGetUniformLocation(program, "iMouse");

   return true;
}

void single_quad_app::run()
{
   GLfloat res[2];
   res[0] = screen_w;
   res[1] = screen_h;
   while (!glfwWindowShouldClose(window))
   {
      system_ticker.tick();

      glUniform1f(elapsed_time_uniform, GLfloat(glfwGetTime()));

      int width, height;
      glfwGetFramebufferSize(window, &width, &height);
      res[0] = GLfloat(width);
      res[1] = GLfloat(height);
      glUniform2fv(resolution_uniform, 1, res);
      double mx, my;
      glfwGetCursorPos(window, &mx, &my);
      float mouse_pos[2] = { float(mx), float(my) };
      glUniform2fv(mouse_uniform, 1, mouse_pos);

      glViewport(0, 0, width, height);
      glClear(GL_COLOR_BUFFER_BIT);

      glUseProgram(program);
      glBindVertexArray(vao);
      glDrawArrays(GL_TRIANGLES, 0, 6);

      glfwSwapBuffers(window);
      glfwPollEvents();

      if (system_ticker.delta < 1.0 / 60.0)
      {
         const unsigned long time_to_delay = long(((1.f / 60.0) - system_ticker.delta) * 1000.0);
         std::this_thread::sleep_for(std::chrono::milliseconds(time_to_delay));
      }
   }
}

void single_quad_app::destroy()
{
   glDeleteProgram(program);
   glDeleteShader(vert_shader);
   glDeleteShader(frag_shader);
   glDeleteBuffers(1, &vbo);
   glDeleteVertexArrays(1, &vao);
   glfwDestroyWindow(window);
   glfwTerminate();
}
