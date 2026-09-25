#pragma once
#include "cog.h"
#include <RaeptorCogs/Cog/function_registry.h>
#define RAEPTOR_CONTAINERS_SHORT_PREFIX
#include <RaeptorContainers/auto.h>
#include <RaeptorContainers/dynamic_array.h>
#include <RaeptorContainers/hash_table.h>
#include <dlfcn.h>
#include <libgen.h>
#include <limits.h>
#include <stdio.h>
#include <unistd.h>

typedef RC_hash_table(uint32_t, function_t) function_registry_table_t;
typedef RC_hash_table(uint32_t,
                      RC_darray(function_t) *) history_registry_table_t;

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

shared_context_t context;

void function_registry_bind(const char *key, function_t f) {
  uint32_t key_hash = RC_hash(key);
  function_registry_table_t *table = context.fn_registry.table;
  history_registry_table_t *history_table = context.fn_registry.history_table;
  if (RC_hash_table_contains(table, key_hash)) {
    __typeof__(history_table->buckets[0]->value) history;
    if (!RC_hash_table_contains(history_table, key_hash)) {
      history = RC_darray_create(__typeof__(*history_table->buckets[0]->value));
      RC_hash_table_insert(history_table, key_hash, history);
    } else {
      history = RC_hash_table_get(history_table, key_hash);
    }
    RC_darray_push(history, RC_hash_table_get(table, key_hash));
  }
  RC_hash_table_insert(table, key_hash, f);
}
void function_registry_unbind(const char *key, function_t f) {
  uint32_t key_hash = RC_hash(key);
  function_registry_table_t *table = context.fn_registry.table;
  history_registry_table_t *history_table = context.fn_registry.history_table;
  if (RC_hash_table_contains(table, key_hash)) {
    if (RC_hash_table_get(table, key_hash) == f) {
      if (RC_hash_table_contains(history_table, key_hash)) {
        auto history = RC_hash_table_get(history_table, key_hash);
        if (history->count > 0) {
          function_t last_fn = RC_darray_pop(history);
          RC_hash_table_insert(table, key_hash, last_fn);
          return;
        }
      } else {
        RC_hash_table_remove(table, key_hash);
        return;
      }
    }
  }
  if (RC_hash_table_contains(history_table, key_hash)) {
    auto history = RC_hash_table_get(history_table, key_hash);
    for (size_t i = 0; i < history->count; ++i) {
      if (history->items[i] == f) {
        RC_darray_remove(history, i);
        return;
      }
    }
  }
}
void(*function_registry_get(const char *key)) {
  uint32_t key_hash = RC_hash(key);
  function_registry_table_t *table = context.fn_registry.table;
  return RC_hash_table_get(table, key_hash);
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
  shared_context_t **shared_context_ptr = dlsym(*handle, "shared_context");

  char *error = dlerror();
  if (error) {
    fprintf(stderr, "Error finding symbol 'cog_entry_point': %s\n", error);
    dlclose(*handle);
    return 1;
  }

  context.fn_registry.bind = function_registry_bind;
  context.fn_registry.unbind = function_registry_unbind;
  context.fn_registry.get = function_registry_get;
  function_registry_table_t *table =
      RC_hash_table_create(function_registry_table_t);
  history_registry_table_t *history_table =
      RC_hash_table_create(history_registry_table_t);
  context.fn_registry.table = table;
  context.fn_registry.history_table = history_table;
  *shared_context_ptr = &context;

  return 0;
}

int unload_prime_mover(void **handle) {
  function_registry_table_t *table = context.fn_registry.table;
  history_registry_table_t *history_table = context.fn_registry.history_table;
  if (*handle) {
    dlclose(*handle);
    *handle = NULL;
  }
  RC_hash_table_free(table);
  RC_hash_table_foreach(history_table, node, {
    RC_darray_free(node->value);
    free(node->value);
  });
  RC_hash_table_free(history_table);
  free(table);
  free(history_table);
  return 0;
}
