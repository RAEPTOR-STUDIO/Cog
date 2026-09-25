include("${CMAKE_CURRENT_LIST_DIR}/CogInfoBuilder.cmake")
set(COGS_DIR
    "${CMAKE_BINARY_DIR}/cogs"
)

function(CogCreate name)
  set(COG_VERSION "1.0.0")
  configure_file(
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Cog.c.in
      ${CMAKE_CURRENT_BINARY_DIR}/Cog.c
      @ONLY
  )

  add_custom_target(${name}
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${CMAKE_BINARY_DIR}/${name}
      ${COGS_DIR}/${name}
  )
  add_custom_target(${name}_dependencies)
  add_dependencies(${name} ${name}_dependencies)
  set(COG_TYPE ${COGS_TYPE_DOMAIN})
  if (ARGN)
    add_library(${name}_binaries SHARED
      ${CMAKE_CURRENT_BINARY_DIR}/Cog.c
      ${ARGN}
    )
    target_include_directories(${name}_binaries
      PUBLIC
      ${CMAKE_CURRENT_SOURCE_DIR}/include
    )
    add_dependencies(${name} ${name}_binaries)
    set_target_properties(${name}_binaries PROPERTIES
      OUTPUT_NAME ${name}
    )
    set_target_properties(${name}_binaries PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${name}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${name}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/${name}"
    )
    set(COG_TYPE ${COGS_TYPE_BINARY})
    # Check if sources contains definition of int cog_entry_point(...)
    if (ARGN)
      foreach(source ${ARGN})
        file(READ ${source} source_content)
        if (source_content MATCHES "int cog_entry_point\\s*\\(")
          set(COG_TYPE ${COGS_TYPE_PRIME_MOVER})
          break()
        endif()
      endforeach()
    endif()
  endif()
  CogInfoFileCreate(${name} ${COG_VERSION} ${COG_TYPE})
  add_custom_target(${name}_create_cog)
  add_dependencies(${name} ${name}_create_cog)
endfunction()

function(CogVersion name version)
  set(COG_VERSION ${version})
  configure_file(
      ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/Cog.c.in
      ${CMAKE_CURRENT_BINARY_DIR}/Cog.c
      @ONLY
  )
  CogInfoFileUpdateVersion(${name} ${version})
endfunction()

function(CogAttachLib name lib)
  target_link_libraries(${name}_binaries
    PRIVATE
      ${lib}
  )
endfunction()

function(CogLoad path cog)
  set(IS_REMOTE FALSE)

  # Check if file exists
  if(NOT EXISTS "${PROJECT_SOURCE_DIR}/${path}")
    set(IS_REMOTE TRUE)
  endif()

  # Confirm it is url
  if(IS_REMOTE)
    if(NOT path MATCHES "^(https?|git)://")
      message(FATAL_ERROR "Invalid URL: ${path}")
    endif()
  endif()

  if (IS_REMOTE)
    ExternalProject_Add(${cog}
        GIT_REPOSITORY ${path}
        GIT_TAG        main

        BINARY_DIR "${CMAKE_BINARY_DIR}/external/${cog}-bin"

        PREFIX         "${CMAKE_BINARY_DIR}/external/${cog}-prefix"

        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${EXTERNAL_INSTALL_DIR}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}

        BUILD_COMMAND
            ${CMAKE_COMMAND} --build <BINARY_DIR>
            --target ${cog}
    )
  else()
    # Check if not already added
    if (NOT TARGET ${cog})
      add_subdirectory(${path} ${CMAKE_BINARY_DIR}/external/${cog}-bin)
    endif()
  endif()
endfunction()

function(CogDeclareDomain cog domain)
  # Add a copy command at the end to the BINARY_DIR
  add_custom_target(${cog}_domain
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      ${CMAKE_CURRENT_SOURCE_DIR}/${domain}
      ${CMAKE_BINARY_DIR}/${cog}/domain/RaeptorCogs/Domain/${cog}
  )
  add_dependencies(${cog} ${cog}_domain)
endfunction()

function(CogRequireCogs name)
  add_dependencies(${name}_dependencies ${ARGN})
endfunction()


function(CogUseCogDomain cog domain)
  target_include_directories(${cog}_binaries
    PRIVATE
    ${COGS_DIR}/${domain}/domain
  )
endfunction()

function(CogRequireCogsDomains name)
  foreach(domain ${ARGN})
    add_dependencies(${name}_dependencies ${domain})
    CogUseCogDomain(${name} ${domain})
    CogInfoFileUpdateDomainDependencies(${name} ${domain})
  endforeach()
endfunction()

function(CogExtendsCogsDomains name)
  foreach(domain ${ARGN})
    add_dependencies(${name}_dependencies ${domain})
    CogUseCogDomain(${name} ${domain})
    CogInfoFileUpdateExtends(${name} ${domain})
  endforeach()
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
      ${CMAKE_BINARY_DIR}/Starter.c
      @ONLY
  )
  add_executable(Starter
      ${CMAKE_BINARY_DIR}/Starter.c
  )
  add_dependencies(Starter ${COG_ENTRY_POINT} ${COG_STARTER_COG_LIST})
endfunction()
