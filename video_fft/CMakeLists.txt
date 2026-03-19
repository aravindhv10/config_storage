cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project(video_fft VERSION 1.0 DESCRIPTION "Code to evaluate FFT of videos")

find_package(Torch REQUIRED)
find_package(OpenCV REQUIRED)

add_library(mytorch SHARED src/main.cpp)

target_link_libraries(mytorch "${TORCH_LIBRARIES}" "${OpenCV_LIBS}")
# target_link_libraries(mytorch "${TORCH_LIBRARIES}")

set_target_properties(mytorch PROPERTIES VERSION ${PROJECT_VERSION} CXX_STANDARD 17)
install(TARGETS mytorch LIBRARY DESTINATION lib)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3 -mtune=native -march=native -flto")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -O3 -mtune=native -march=native -flto")
set(CMAKE_INSTALL_PREFIX "/usr")
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
