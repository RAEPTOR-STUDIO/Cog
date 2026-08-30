#pragma once
#include "cog.h"
#include <RaeptorCogs/Cog/function_registry.h>
#include <RaeptorContainers/auto.h>
#include <RaeptorContainers/dynamic_array.h>
#include <RaeptorContainers/hash_table.h>
#include <RaeptorParallel/Workers/worker.h>
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

shared_context_t context;

void function_registry_bind(const char *key, function_t f) {
  uint32_t key_hash = RC_hash(key);
  if (RC_hash_table_contains(&context.fn_registry.table, key_hash)) {
    __typeof__(context.fn_registry.history_table.buckets[0]->value) history;
    if (!RC_hash_table_contains(&context.fn_registry.history_table, key_hash)) {
      history = RC_darray_create(
          __typeof__(context.fn_registry.history_table.buckets[0]->value));
      RC_hash_table_insert(&context.fn_registry.history_table, key_hash,
                           history);
    } else {
      history = RC_hash_table_get(&context.fn_registry.history_table, key_hash);
    }
    RC_darray_push(history,
                   RC_hash_table_get(&context.fn_registry.table, key_hash));
  }
  RC_hash_table_insert(&context.fn_registry.table, key_hash, f);
}
void function_registry_unbind(const char *key, function_t f) {
  uint32_t key_hash = RC_hash(key);
  if (RC_hash_table_contains(&context.fn_registry.table, key_hash)) {
    if (RC_hash_table_get(&context.fn_registry.table, key_hash) == f) {
      if (RC_hash_table_contains(&context.fn_registry.history_table,
                                 key_hash)) {
        auto history =
            RC_hash_table_get(&context.fn_registry.history_table, key_hash);
        if (history->count > 0) {
          function_t last_fn = RC_darray_pop(history);
          RC_hash_table_insert(&context.fn_registry.table, key_hash, last_fn);
          return;
        }
      } else {
        RC_hash_table_remove(&context.fn_registry.table, key_hash);
        return;
      }
    }
  }
  if (RC_hash_table_contains(&context.fn_registry.history_table, key_hash)) {
    auto history =
        RC_hash_table_get(&context.fn_registry.history_table, key_hash);
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
  return RC_hash_table_get(&context.fn_registry.table, key_hash);
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
  RC_hash_table_init(&context.fn_registry.table);
  RC_hash_table_init(&context.fn_registry.history_table);

  worker_init(&context.workers.main_worker, pthread_self());
  *shared_context_ptr = &context;

  return 0;
}

int unload_prime_mover(void **handle) {
  if (*handle) {
    dlclose(*handle);
    *handle = NULL;
  }
  RC_hash_table_free(&context.fn_registry.table);
  RC_hash_table_foreach(&context.fn_registry.history_table, node, {
    RC_darray_free(node->value);
    free(node->value);
  });
  RC_hash_table_free(&context.fn_registry.history_table);
  return 0;
}
