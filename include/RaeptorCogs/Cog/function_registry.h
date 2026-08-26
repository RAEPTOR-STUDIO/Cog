#pragma once
#include <RaeptorContainers/dynamic_array.h>
#include <RaeptorContainers/hash_table.h>
typedef void(*function_t);
typedef hash_table(const char *, function_t) function_registry_table_t;
typedef struct function_registry {
  function_registry_table_t *table;
  void (*bind)(const char *key, function_t t);
  function_t (*get)(const char *key);
} function_registry_t;

void function_registry_bind(const char *key, function_t t);
function_t function_registry_get(const char *key);

extern function_registry_t *fn_registry;

#ifdef IMPLEMENTS_FUNCTION_REGISTRY
function_registry_t *fn_registry;

void function_registry_bind(const char *key, function_t f) {
  hash_table_insert(fn_registry->table, key, f);
}
void(*function_registry_get(const char *key)) {
  return hash_table_get(fn_registry->table, key);
}

__attribute__((constructor)) static void init_registry(void) {
  fn_registry = malloc(sizeof(function_registry_t));
  fn_registry->table = hash_table_create(function_registry_table_t);
  fn_registry->bind = function_registry_bind;
  fn_registry->get = function_registry_get;
}
#endif
