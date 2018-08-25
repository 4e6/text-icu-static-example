cmake_minimum_required (VERSION 3.7)
project (Example)

find_package(ICU 59.0 COMPONENTS io i18n REQUIRED)
#include_directories(${ICU_INCLUDE_DIRS})
#link_directories(${ICU_LIBRARIES})
message(STATUS "ICU_INCLUDE_DIRS=${ICU_INCLUDE_DIRS}")
message(STATUS "ICU_LIBRARIES=${ICU_LIBRARIES}")

add_executable(Test test.c)
target_link_libraries(Test ICU::io ICU::i18n)
#target_link_libraries(Test ${ICU_LIBRARIES})
#target_link_libraries(Test PUBLIC -static)
install(TARGETS Test DESTINATION bin)
