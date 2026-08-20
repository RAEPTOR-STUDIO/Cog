function(CreateCog name)
  cmake_minimum_required(VERSION 3.16)
  project(Cog LANGUAGES C)
  set(PROJECT_NAMESPACE ${name})
  set(CMAKE_C_STANDARD 23)
  add_library(${name} SHARED
    src/RaeptorCogs/${name}/cog-main.c
  )
endfunction()
