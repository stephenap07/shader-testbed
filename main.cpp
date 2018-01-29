// OpenGL boiler plate code to render a single quad
// For use of shader code
// Stephen Pridham

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <stdio.h>
#include <stdlib.h>

#include <chrono>
#include <thread>

#include "clock.h"
#include "opengl_util.h"

static void error_callback(int error, const char* description)
{
   fprintf(stderr, "Error: %s\n", description);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
   if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
      glfwSetWindowShouldClose(window, GLFW_TRUE);
}

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

int main()
{
   GLFWwindow* window;
   glfwSetErrorCallback(error_callback);

   if (!glfwInit())
      exit(EXIT_FAILURE);

   glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
   glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
   glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
   glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

   const int screen_w = 1280;
   const int screen_h = 720;
   window = glfwCreateWindow(screen_w, screen_h, "SDF", nullptr, nullptr);

   if (!window)
   {
      exit(EXIT_FAILURE);
   }

   glfwSetKeyCallback(window, key_callback);

   glfwMakeContextCurrent(window);
   glewExperimental = GL_TRUE;
   glewInit();
   glfwSwapInterval(1);

   GLuint vao;
   glGenVertexArrays(1, &vao);
   glBindVertexArray(vao);

   GLuint vbo;
   glGenBuffers(1, &vbo);
   glBindBuffer(GL_ARRAY_BUFFER, vbo);
   glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

   GLuint program = glCreateProgram();
   GLuint vertexShader = compile_shader_from_file(GL_VERTEX_SHADER, "vertex.glsl");
   GLuint fragmentShader = compile_shader_from_file(GL_FRAGMENT_SHADER, "raymarch.glsl");
   glAttachShader(program, vertexShader);
   glAttachShader(program, fragmentShader);
   glLinkProgram(program);
   glDeleteShader(vertexShader);
   glDeleteShader(fragmentShader);

   glUseProgram(program);
   GLint pos_attrib = glGetAttribLocation(program, "position");
   glVertexAttribPointer(pos_attrib, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), (void*)0);
   glEnableVertexAttribArray(pos_attrib);

   GLint elapsed_time_uniform = glGetUniformLocation(program, "iTime");
   GLint resolution_uniform = glGetUniformLocation(program, "iResolution");
   GLint mouse_uniform = glGetUniformLocation(program, "iMouse");
   ticker system_ticker;

   GLfloat res[2];
   res[0] = screen_w;
   res[1] = screen_h;
   while (!glfwWindowShouldClose(window))
   {
      system_ticker.tick();

      glUniform1f(elapsed_time_uniform, GLfloat(glfwGetTime()));

      int width, height;
      glfwGetFramebufferSize(window, &width, &height);
      res[0] = width;
      res[1] = height;
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

   glfwDestroyWindow(window);
   glfwTerminate();

   return EXIT_SUCCESS;
}
