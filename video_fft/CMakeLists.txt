cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project(aoti_example VERSION 1.0 DESCRIPTION "Interface for inferring with libtorch exposed to rust")

find_package(Torch REQUIRED)
find_package(OpenCV REQUIRED)

add_executable(aoti_example src/test.cpp)
add_library(mytorch SHARED src/main.cpp)

target_link_libraries(aoti_example "${TORCH_LIBRARIES}" "${OpenCV_LIBS}")
target_link_libraries(mytorch "${TORCH_LIBRARIES}" "${OpenCV_LIBS}")

set_property(TARGET aoti_example PROPERTY CXX_STANDARD 17)
set_target_properties(mytorch PROPERTIES VERSION ${PROJECT_VERSION} CXX_STANDARD 17)

install(TARGETS mytorch LIBRARY DESTINATION lib)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -mtune=native -march=native -flto")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -O3 -mtune=native -march=native -flto")
set(CMAKE_INSTALL_PREFIX "/usr")
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
