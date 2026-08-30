#pragma once
#include <stdint.h>
#define RAEPTOR_CONTAINERS_SHORT_PREFIX
#include <RaeptorContainers/dynamic_array.h>
#include <RaeptorContainers/hash_table.h>
#include <stdio.h>
typedef void(*function_t);
typedef RC_hash_table(uint32_t, function_t) function_registry_table_t;
typedef RC_hash_table(uint32_t,
                      RC_darray(function_t) *) history_registry_table_t;
typedef struct function_registry {
  function_registry_table_t table;
  history_registry_table_t history_table;
  void (*bind)(const char *key, function_t t);
  void (*unbind)(const char *key, function_t t);
  function_t (*get)(const char *key);
} function_registry_t;
