INCLUDE=`pkg-config --cflags glfw3`
CXXFLAGS=-std=c++1z -arch x86_64 $(INCLUDE)
LIBS=-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo -lglew `pkg-config --static --libs glfw3`

all: sdf

opt: CXXFLAGS += -O3

debug: CXXFLAGS += -DDEBUG -g -fsanitize=address

clean:
	rm sdf obj/*.o

sdf: obj obj/main.o obj/single_quad_app.o obj/imgui.o obj/imgui_draw.o obj/imgui_impl_glfw_gl3.o obj/imgui_demo.o
	$(CXX) $(CXXFLAGS) obj/main.o obj/single_quad_app.o obj/imgui.o obj/imgui_draw.o obj/imgui_impl_glfw_gl3.o obj/imgui_demo.o -o sdf $(LIBS)

obj:
	mkdir -p obj

obj/main.o: main.cpp single_quad_app.h
	$(CXX) $(CXXFLAGS) -c main.cpp -o obj/main.o

obj/single_quad_app.o: single_quad_app.cpp single_quad_app.h
	$(CXX) $(CXXFLAGS) -c single_quad_app.cpp -o obj/single_quad_app.o

# External dependencies
obj/imgui.o: extern/imgui/imgui.cpp extern/imgui/imgui.h
	$(CXX) $(CXXFLAGS) -Iextern/imgui -c extern/imgui/imgui.cpp -o obj/imgui.o

obj/imgui_draw.o: extern/imgui/imgui.cpp
	$(CXX) $(CXXFLAGS) -Iextern/imgui -c extern/imgui/imgui_draw.cpp -o obj/imgui_draw.o

obj/imgui_impl_glfw_gl3.o: extern/imgui_impl/imgui_impl_glfw_gl3.cpp
	$(CXX) $(CXXFLAGS) -Iextern/imgui -Iextern/imgui_impl -c extern/imgui_impl/imgui_impl_glfw_gl3.cpp -o obj/imgui_impl_glfw_gl3.o

obj/imgui_demo.o: extern/imgui/imgui_demo.cpp
	$(CXX) $(CXXFLAGS) -Iextern/imgui -Iextern/imgui_impl -c extern/imgui/imgui_demo.cpp -o obj/imgui_demo.o
