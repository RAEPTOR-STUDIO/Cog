#pragma once
#include <stdint.h>
#include <stdio.h>
typedef void(*function_t);
typedef struct function_registry {
  void *table;
  void *history_table;
  void (*bind)(const char *key, function_t t);
  void (*unbind)(const char *key, function_t t);
  function_t (*get)(const char *key);
} function_registry_t;

#define BindFunction(name)                                                     \
  do {                                                                         \
    shared_context->fn_registry.bind(#name, (function_t)name);                 \
  } while (0)

#define UnbindFunction(name)                                                   \
  do {                                                                         \
    shared_context->fn_registry.unbind(#name, (function_t)name);               \
  } while (0)
