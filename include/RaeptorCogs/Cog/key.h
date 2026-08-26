#pragma once
#include <RaeptorContainers/hash.h>
#include <stdint.h>

typedef uint32_t cog_key_t;

// concat 16 bits hash from cog_name + 16 bits hash from str :
#define cog_key(str)                                                           \
  ((cog_key_t)((((uint32_t)hash16(cog_name())) << 16) |                        \
               ((uint32_t)hash16(str))))
