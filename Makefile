INCLUDE=`pkg-config --cflags glfw3`
CXXFLAGS=-std=c++1z -arch x86_64 $(INCLUDE)
LIBS=-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo -lglew `pkg-config --static --libs glfw3`

all:
	$(CXX) $(CXXFLAGS) main.cpp -o sdf $(LIBS)

opt: CXXFLAGS += -O3
opt:
	$(CXX) $(CXXFLAGS) main.cpp -o sdf $(LIBS)

debug: CXXFLAGS += -DDEBUG -g -fsanitize=address
debug:
	$(CXX) $(CXXFLAGS) main.cpp -o sdf $(LIBS)

clean:
	rm sdf
