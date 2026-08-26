#pragma once
#include <RaeptorCogs/Cog/function_registry.h>

#define cog_build(_cog_name)                                                   \
  const char *cog_version() { return "1.0.0"; }                                \
  const char *cog_name() { return _cog_name; }                                 \
  function_registry_t *fn_registry;
