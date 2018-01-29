INCLUDE=`pkg-config --cflags glfw3`
CXXFLAGS=-std=c++1z -arch x86_64 $(INCLUDE)
LIBS=-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo -lglew `pkg-config --static --libs glfw3`

all: sdf

opt: CXXFLAGS += -O3

debug: CXXFLAGS += -DDEBUG -g -fsanitize=address

clean:
	rm sdf *.o

sdf: main.o single_quad_app.o
	$(CXX) $(CXXFLAGS) main.o single_quad_app.o -o sdf $(LIBS)

main.o: main.cpp single_quad_app.h
	$(CXX) $(CXXFLAGS) -c main.cpp

single_quad_app.o: single_quad_app.cpp single_quad_app.h
	$(CXX) $(CXXFLAGS) -c single_quad_app.cpp
