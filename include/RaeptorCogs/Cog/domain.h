#pragma once
#include <RaeptorCogs/Cog/cog.h>
#include <RaeptorCogs/Cog/function_registry.h>

#define DomainFunction(ret_type, name, ...)                                    \
  static inline ret_type (*name##_api(void))(__VA_ARGS__) {                    \
    ret_type (*fn)(__VA_ARGS__) =                                              \
        (ret_type (*)(__VA_ARGS__))shared_context->fn_registry.get(#name);     \
    return fn;                                                                 \
  }                                                                            \
  ret_type name(__VA_ARGS__);
