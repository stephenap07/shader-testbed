#include "single_quad_app.h"

#include <stdio.h>
#include <stdlib.h>

#include <chrono>
#include <thread>

#include "extern/imgui/imgui.h"
#include "extern/imgui_impl/imgui_impl_glfw_gl3.h"

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

struct GL_state
{
   GLuint vao;
   GLuint vbo;
   GLint pos_attrib;
   GLuint program;
   GLuint vert_shader;
   GLuint frag_shader;

   GLint elapsed_time_uniform;
   GLint resolution_uniform;
   GLint mouse_uniform;
   GLint color_uniform;
   GLint shininess_uniform;
} gl_state;

void reloadShaders()
{
   auto vert_shader = compile_shader_from_file(GL_VERTEX_SHADER, "shaders/vertex.glsl");
   auto frag_shader = compile_shader_from_file(GL_FRAGMENT_SHADER, "shaders/raymarch.glsl");
   if (!vert_shader || !frag_shader)
   {
      fprintf(stderr, "Failed to load shaders\n");
   }
   else
   {
      gl_state.vert_shader = vert_shader;
      gl_state.frag_shader = frag_shader;
      if (gl_state.program)
         glDeleteProgram(gl_state.program);
      gl_state.program = glCreateProgram();
      glAttachShader(gl_state.program, gl_state.vert_shader);
      glAttachShader(gl_state.program, gl_state.frag_shader);
      glDeleteShader(gl_state.vert_shader);
      glDeleteShader(gl_state.frag_shader);
      glLinkProgram(gl_state.program);
      gl_state.elapsed_time_uniform = glGetUniformLocation(gl_state.program, "iTime");
      gl_state.resolution_uniform = glGetUniformLocation(gl_state.program, "iResolution");
      gl_state.mouse_uniform = glGetUniformLocation(gl_state.program, "iMouse");
      gl_state.color_uniform = glGetUniformLocation(gl_state.program, "iColor");
      gl_state.shininess_uniform = glGetUniformLocation(gl_state.program, "iShininess");
   }
}

static void error_callback(int error, const char* description)
{
   fprintf(stderr, "Error: %s\n", description);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
   if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
      glfwSetWindowShouldClose(window, GLFW_TRUE);
   if (key == GLFW_KEY_R && action == GLFW_PRESS)
      reloadShaders();
   ImGui_ImplGlfwGL3_KeyCallback(window, key, scancode, action, mods);
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
   {
      fprintf(stderr, "Failed to initialize GLFW3\n");
      return false;
   }

   glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
   glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
   glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
   glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

   window = glfwCreateWindow(screen_w, screen_h, "SDF", nullptr, nullptr);

   if (!window)
   {
      fprintf(stderr, "Failed to initialize GLFW3 window\n");
      return false;
   }

   glfwSetKeyCallback(window, key_callback);

   glfwMakeContextCurrent(window);
   glewExperimental = GL_TRUE;
   glewInit();
   glfwSwapInterval(1);

   // Setup ImGui binding
   ImGui_ImplGlfwGL3_Init(window, false);
   // Setup imgui callbacks for keyboard/mouse input
   glfwSetMouseButtonCallback(window, ImGui_ImplGlfwGL3_MouseButtonCallback);
   glfwSetScrollCallback(window, ImGui_ImplGlfwGL3_ScrollCallback);
   glfwSetCharCallback(window, ImGui_ImplGlfwGL3_CharCallback);
   ImGui::StyleColorsLight();

   glGenVertexArrays(1, &gl_state.vao);
   glBindVertexArray(gl_state.vao);

   glGenBuffers(1, &gl_state.vbo);
   glBindBuffer(GL_ARRAY_BUFFER, gl_state.vbo);
   glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

   reloadShaders();
   glUseProgram(gl_state.program);
   gl_state.pos_attrib = glGetAttribLocation(gl_state.program, "position");
   glVertexAttribPointer(gl_state.pos_attrib, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), (void*)0);
   glEnableVertexAttribArray(gl_state.pos_attrib);

   return true;
}

void single_quad_app::run()
{
   GLfloat res[2] = { GLfloat(screen_w), GLfloat(screen_h) };
   bool show_sdf_properties_window = true;
   ImVec4 object_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
   while (!glfwWindowShouldClose(window))
   {
      system_ticker.tick();
      glfwGetCursorPos(window, &mouse_x, &mouse_y);
      glfwGetFramebufferSize(window, &screen_w, &screen_h);

      ImGui_ImplGlfwGL3_NewFrame();
      glViewport(0, 0, screen_w, screen_h);

      glClear(GL_COLOR_BUFFER_BIT);
      draw_quad();

      {
         ImGui::Begin("SDF Properties", &show_sdf_properties_window);
         static float shininess = 0.0f;
         if (ImGui::SliderFloat("float", &shininess, 1.0f, 80.0f))
            glUniform1f(gl_state.shininess_uniform, shininess);
         ImGui::Text("Change the color of objects"); // Some text (you can use a format string too)
         if (ImGui::ColorEdit3("Object color", (float*)&object_color))
            glUniform4fv(gl_state.color_uniform, 1, (float*)&object_color);
         ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
         ImGui::End();
      }

      ImGui::Render();

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
   glDeleteProgram(gl_state.program);
   glDeleteBuffers(1, &gl_state.vbo);
   glDeleteVertexArrays(1, &gl_state.vao);
   ImGui_ImplGlfwGL3_Shutdown();
   glfwDestroyWindow(window);
   glfwTerminate();
}

void single_quad_app::draw_quad()
{
   glUniform1f(gl_state.elapsed_time_uniform, GLfloat(glfwGetTime()));
   GLfloat res[2] = { GLfloat(screen_w), GLfloat(screen_h) };
   glUniform2fv(gl_state.resolution_uniform, 1, res);
   float mouse_pos[2] = { float(mouse_x), float(mouse_y) };
   glUniform2fv(gl_state.mouse_uniform, 1, mouse_pos);
   glUseProgram(gl_state.program);
   glBindVertexArray(gl_state.vao);
   glDrawArrays(GL_TRIANGLES, 0, 6);
}
