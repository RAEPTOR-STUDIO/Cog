#pragma once
#include <RaeptorCogs/Cog/function_registry.h>
#include <RaeptorParallel/Jobs/job.h>
#include <RaeptorParallel/Workers/worker.h>

typedef struct shared_context {
  function_registry_t fn_registry;
  struct {
    worker_t main_worker;
  } workers;
} shared_context_t;

#define cog_build(_cog_name)                                                   \
  const char *cog_version() { return "1.0.0"; }                                \
  const char *cog_name() { return _cog_name; }                                 \
  shared_context_t *shared_context;

extern shared_context_t *shared_context;
