#define cog_build(_cog_name)                                                   \
  const char *cog_version() { return "1.0.0"; }                                \
  const char *cog_name() { return _cog_name; }

#define cog_endpoint(endpoint)                                                 \
  int endpoint(void) { return 0; }
