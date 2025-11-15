add_subdirectory(C++)

if( ${CMAKE_SYSTEM_NAME} STREQUAL "Linux" OR ${CMAKE_SYSTEM_NAME} STREQUAL "Darwin" )

if (QUICKFIX_EXAMPLES)
  add_executable(at at.cpp getopt.c)
  
  target_include_directories(at PRIVATE ${PROJECT_SOURCE_DIR} 
    ${PROJECT_SOURCE_DIR}/src/C++)
    
  target_link_libraries(at ${PROJECT_NAME})
  
  ADD_CUSTOM_TARGET(at_target ALL
                    COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:at> ${PROJECT_SOURCE_DIR}/test/at)
endif()  

if (QUICKFIX_EXAMPLES)
  add_executable(pt pt.cpp getopt.c)
  
  target_include_directories(pt PRIVATE ${PROJECT_SOURCE_DIR} 
    ${PROJECT_SOURCE_DIR}/src/C++)
    
  target_link_libraries(pt ${PROJECT_NAME})
  
  ADD_CUSTOM_TARGET(pt_target ALL
                    COMMAND ${CMAKE_COMMAND} -E create_symlink $<TARGET_FILE:pt> ${PROJECT_SOURCE_DIR}/test/pt)
endif()  

endif()