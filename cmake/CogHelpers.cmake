function(CogCreate name)
  configure_file(
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Cog.c.in
      ${CMAKE_CURRENT_BINARY_DIR}/Cog.c
      @ONLY
  )

  add_library(${name} SHARED
    ${CMAKE_CURRENT_BINARY_DIR}/Cog.c
    ${ARGN}
  )
  set_target_properties(${name} PROPERTIES
      ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${name}"
      LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${name}"
      RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${name}"
  )
endfunction()
function(CogAttachLib name lib)
  target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
      ${lib}
  )
  add_custom_command(TARGET ${name} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      $<TARGET_FILE:${lib}>
      $<TARGET_FILE_DIR:${name}>
  )
endfunction()
