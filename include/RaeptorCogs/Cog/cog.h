#pragma once
#include <RaeptorCogs/Cog/function_registry.h>
#include <RaeptorParallel/Jobs/job.h>

typedef struct shared_context {
  function_registry_t fn_registry;
  void *data;
} shared_context_t;

#define cog_build(_cog_name, _cog_version)                                     \
  const char *cog_version() { return _cog_version; }                           \
  const char *cog_name() { return _cog_name; }                                 \
  shared_context_t *shared_context;

extern shared_context_t *shared_context;

int cog_entry_point(int argc, const char **argv);
