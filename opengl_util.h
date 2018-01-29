#include <GL/glew.h>

#include <stdio.h>
#include <stdlib.h>

#include <cctype>

// Compile shader from a file. Return 0 on error.
GLuint compile_shader(GLenum shader_type, const GLchar* shaderSource, GLint len)
{
   GLuint shader = glCreateShader(shader_type);
   glShaderSource(shader, 1, &shaderSource, &len);
   glCompileShader(shader);
   GLint success = 0;
   glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
   if (success == GL_FALSE)
   {
      GLint lsize = 0;
      glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &lsize);
      if (lsize)
      {
         GLchar* errorLog = new GLchar[lsize];
         glGetShaderInfoLog(shader, lsize, &lsize, errorLog);
         fprintf(stderr, "Error with shader %s\n", errorLog);
         delete[] errorLog;
         return 0;
      }
   }
   return shader;
}

// Compile shader from a file. Return 0 on error.
GLuint compile_shader_from_file(GLenum shader_type, const char* filename)
{
   FILE* fp = fopen(filename, "rb");
   if (!fp)
   {
      fprintf(stderr, "Failed to load shader file %s\n", filename);
      return 0;
   }
   fseek(fp, 0, SEEK_END);
   const size_t file_size = ftell(fp);
   rewind(fp);
   if (!file_size)
   {
      fclose(fp);
      fprintf(stderr, "File is empty %s\n", filename);
   }
   char* buffer = new char[file_size + 1];
   fread(buffer, file_size, 1, fp);
   buffer[file_size] = '\0';
   GLuint shader = compile_shader(shader_type, buffer, GLint(file_size));
   if (!shader)
   {
      fprintf(stderr, "Failed to load shader %s\n", filename);
   }
   fclose(fp);
   delete[] buffer;
   return shader;
}
