cmake_minimum_required (VERSION 3.7)
project (Example)

set(CMAKE_VERBOSE_MAKEFILE on)
find_package(ICU 59.0 COMPONENTS data i18n io uc REQUIRED)
message(STATUS "ICU_INCLUDE_DIRS=${ICU_INCLUDE_DIRS}")
message(STATUS "ICU_LIBRARIES=${ICU_LIBRARIES}")

add_executable(Test test.c)
target_link_libraries(Test ${ICU_LIBRARIES} -static -pthread -licuio -licui18n -licuuc -licudata -lpthread -ldl -lm -lstdc++)
install(TARGETS Test DESTINATION bin)
