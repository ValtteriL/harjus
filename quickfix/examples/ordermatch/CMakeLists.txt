add_executable(ordermatch Application.cpp Market.cpp ordermatch.cpp ${applink_SOURCE})

target_include_directories(ordermatch PRIVATE ${PROJECT_SOURCE_DIR}/include ${PROJECT_SOURCE_DIR}/include/quickfix ${PROJECT_SOURCE_DIR})


target_link_libraries(ordermatch ${PROJECT_NAME})

ADD_CUSTOM_TARGET(ordermatch_target ALL
                  COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:ordermatch> ${PROJECT_SOURCE_DIR}/bin/ordermatch)
