set (executor_NAME executor)

add_executable(${executor_NAME} Application.cpp executor.cpp ${applink_SOURCE})

target_include_directories(${executor_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/include ${PROJECT_SOURCE_DIR}/include/quickfix ${PROJECT_SOURCE_DIR})

target_link_libraries(${executor_NAME} ${PROJECT_NAME})

ADD_CUSTOM_TARGET(${executor_NAME}_target ALL
                  COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:executor> ${PROJECT_SOURCE_DIR}/bin/${executor_NAME})


