// OpenGL boiler plate code to render a single quad
// For use of shader code
// Stephen Pridham

#include "single_quad_app.h"

int main()
{
   single_quad_app app;
   if (!app.init())
   {
      // Failed
      return 1;
   }
   app.run();
   app.destroy();
   return 0;
}
