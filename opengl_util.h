#include <GL/glew.h>

#include <stdio.h>
#include <stdlib.h>

#include <cctype>

// Compile shder from a file. Return 0 on error.
GLuint compile_shader(GLenum shader_type, const GLchar* shaderSource, GLint len)
{
   GLuint shader = glCreateShader(shader_type);
   glShaderSource(shader, 1, &shaderSource, &len);
   glCompileShader(shader);
   GLint success = 0;
   glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
   if (success == GL_FALSE)
   {
      GLint logSize = 0;
      glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logSize);
      if (logSize)
      {
         GLchar* errorLog = new GLchar[logSize];
         glGetShaderInfoLog(shader, logSize, &logSize, errorLog);
         fprintf(stderr, "Error with shader %s\n", errorLog);
         delete[] errorLog;
      }
   }
   return shader;
}

// Compile shader from a file. Return 0 on error.
GLuint compile_shader_from_file(GLenum shader_type, const char* filename)
{
   FILE* fp = fopen(filename, "r");
   if (!fp)
   {
      fprintf(stderr, "Failed to load shader file %s\n", filename);
      return 0;
   }
   size_t file_size = 0;
   fseek(fp, 0, SEEK_END);
   file_size = ftell(fp);
   fseek(fp, 0, SEEK_SET);
   if (file_size == 0)
   {
      fclose(fp);
      fprintf(stderr, "File is empty %s\n", filename);
   }
   char* contents = new char[file_size];
   fread(contents, 1, file_size, fp);
   GLuint shader = compile_shader(shader_type, contents, GLint(file_size));
   fclose(fp);
   delete[] contents;
   return shader;
}
