#pragma once
#include <RaeptorCogs/Cog/function_registry.h>
#include <dlfcn.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <unistd.h>

int localize_cwd(void) {
  char path[PATH_MAX];

  ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
  if (len == -1) {
    perror("readlink");
    return 1;
  }

  path[len] = '\0';

  char *dir = dirname(path);

  if (chdir(dir) == -1) {
    perror("chdir");
    return 1;
  }

  return 0;
}

int load_prime_mover(const char *path, void **handle,
                     void (**cog_entry_point)(int, const char **)) {
  *handle = dlopen(path, RTLD_LAZY);
  if (!*handle) {
    fprintf(stderr, "Error loading shared library: %s\n", dlerror());
    return 1;
  }

  // Load the symbol for the cog entry point
  *cog_entry_point = dlsym(*handle, "cog_entry_point");

  // Link fn_registry from library to actual fn_registry
  function_registry_t **fn_registry_ptr = dlsym(*handle, "fn_registry");

  char *error = dlerror();
  if (error) {
    fprintf(stderr, "Error finding symbol 'cog_entry_point': %s\n", error);
    dlclose(*handle);
    return 1;
  }

  *fn_registry_ptr = fn_registry;

  return 0;
}

int unload_prime_mover(void **handle) {
  if (*handle) {
    dlclose(*handle);
    *handle = NULL;
  }
  return 0;
}
