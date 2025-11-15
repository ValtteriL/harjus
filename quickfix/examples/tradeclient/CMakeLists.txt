add_executable(tradeclient Application.cpp tradeclient.cpp ${applink_SOURCE})

target_include_directories(tradeclient PRIVATE ${PROJECT_SOURCE_DIR}/include ${PROJECT_SOURCE_DIR}/include/quickfix ${PROJECT_SOURCE_DIR})


target_link_libraries(tradeclient ${PROJECT_NAME})

ADD_CUSTOM_TARGET(tradeclient_target ALL
                  COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:tradeclient> ${PROJECT_SOURCE_DIR}/bin/tradeclient)
  

