#ifndef CLOCK_H_
#define CLOCK_H_

#include <GLFW/glfw3.h>

class ticker
{
public:
   double last_time = 0;
   double delta = 0;

   void tick()
   {
      double current = glfwGetTime();
      delta = current - last_time;
      last_time = current;
   }
};

#endif
