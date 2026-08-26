set(COGS_DIR
    "${CMAKE_BINARY_DIR}/cogs"
)
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
  # Copy OUTPUT_DIRECTORY to COGS
  add_custom_command(TARGET ${name} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      $<TARGET_FILE_DIR:${name}>
      ${COGS_DIR}/${name}
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
function(CogLoad path cog)
  set(EXTERNAL_INSTALL_DIR
      ${CMAKE_BINARY_DIR}/external
  )
  set(IS_REMOTE FALSE)

  # Check if file exists
  if(NOT EXISTS ${path})
    set(IS_REMOTE TRUE)
  endif()

  # Confirm it is url
  if(IS_REMOTE EQUAL TRUE AND NOT path MATCHES "^(https?|git)://")
    message(FATAL_ERROR "Invalid URL: ${path}")
  endif()


  if (IS_REMOTE)
    ExternalProject_Add(${cog}
        GIT_REPOSITORY ${path}
        GIT_TAG        main

        BINARY_DIR "${CMAKE_BINARY_DIR}/${cog}-build"

        PREFIX         ${CMAKE_BINARY_DIR}/${cog}

        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_DIR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}

        BUILD_COMMAND
            ${CMAKE_COMMAND} --build <BINARY_DIR>
            --target ${cog}
    )
  else()
    ExternalProject_Add(${cog}
        SOURCE_DIR     "${CMAKE_SOURCE_DIR}/${path}"

        PREFIX "${CMAKE_BINARY_DIR}/${cog}"

        CONFIGURE_COMMAND
            ${CMAKE_COMMAND}
            -S <SOURCE_DIR>
            -B <BINARY_DIR>
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}

        BUILD_COMMAND
            ${CMAKE_COMMAND}
            --build <BINARY_DIR>
            --target ${cog}

        INSTALL_COMMAND ""

        BUILD_ALWAYS TRUE
    )
  endif()

  # copy BINARY_DIR/${cog} to DEST_DIR
  add_custom_command(TARGET ${cog} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${CMAKE_BINARY_DIR}/${cog}/src/${cog}-build/${cog}
      ${COGS_DIR}/${cog}
  )
endfunction()

set(COG_ENTRY_POINT "")
set(COG_STARTER_COG_LIST "")
set(COG_STARTER_TYPE "Default")
function(CogStarterSetEntryPoint cog)
  set(COG_ENTRY_POINT ${cog} PARENT_SCOPE)
endfunction()
function(CogStarterAddCogs)
  foreach(cog ${ARGN})
    list(APPEND COG_STARTER_COG_LIST ${cog})
  endforeach()
  set(COG_STARTER_COG_LIST ${COG_STARTER_COG_LIST} PARENT_SCOPE)
endfunction()
function(CogStarterSetType type)
  set(COG_STARTER_TYPE ${type} PARENT_SCOPE)
endfunction()
function(CogStarterCreate)
  set(COG_STARTER_COG_LIST_C "\"\",\n")
  foreach(cog ${COG_STARTER_COG_LIST})
    set(COG_STARTER_COG_LIST_C "${COG_STARTER_COG_LIST_C} \"${cog}\",\n")
  endforeach()
  configure_file(
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/RaeptorCogsStarter${COG_STARTER_TYPE}.c.in
      ${CMAKE_CURRENT_BINARY_DIR}/Starter.c
      @ONLY
  )
  add_executable(Starter
      ${CMAKE_CURRENT_BINARY_DIR}/Starter.c
  )
  add_dependencies(Starter ${COG_ENTRY_POINT} ${COG_STARTER_COG_LIST})
endfunction()
