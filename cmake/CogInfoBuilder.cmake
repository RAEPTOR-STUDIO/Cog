set(COGS_TYPE_BINARY "BinaryCog")
set(COGS_TYPE_DOMAIN "DomainCog")
set(COGS_TYPE_PRIME_MOVER "PrimeMoverCog")
set(COGS_PURITY_LEVEL Purest Pure Mixed Heavy SuperHeavy)

function(CogInfoFileCreate cog version type)
  file(WRITE "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
"{
  \"name\": \"${cog}\",
  \"version\": \"${version}\",
  \"type\": \"${type}\"
}")
endfunction()

function(CogInfoFileUpdateVersion cog version)
  # Edit version with jq:
  execute_process(
    COMMAND jq ".version = \"${version}\"" "${CMAKE_CURRENT_BINARY_DIR}/${cog}/${cog}.json"
    OUTPUT_VARIABLE COG_JSON_CONTENT
  )
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${cog}/${cog}.json" "${COG_JSON_CONTENT}")
endfunction()

function(CogInfoFileUpdateDomainDependencies cog domain)
  execute_process(
      COMMAND jq -r ".domainDependencies" "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
      OUTPUT_VARIABLE COG_JSON_EXTENDS
    )

  if (NOT COG_JSON_EXTENDS STREQUAL "null")
    execute_process(
        COMMAND jq ".domainDependencies = [\"${domain}\"] + .domainDependencies" "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
        OUTPUT_VARIABLE COG_JSON_CONTENT
      )
  else()
    execute_process(
        COMMAND jq ".domainDependencies = [\"${domain}\"]" "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
        OUTPUT_VARIABLE COG_JSON_CONTENT
      )
  endif()
  file(WRITE "${CMAKE_BINARY_DIR}/${cog}/${cog}.json" "${COG_JSON_CONTENT}")
endfunction()

function(CogInfoFileUpdateExtends cog domain)
  execute_process(
    COMMAND jq -r ".extends" "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
    OUTPUT_VARIABLE COG_JSON_EXTENDS
  )

  if (NOT COG_JSON_EXTENDS STREQUAL "null")
    execute_process(
      COMMAND jq ".extends = [\"${domain}\"] + .extends" "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
      OUTPUT_VARIABLE COG_JSON_CONTENT
    )
  else()
    execute_process(
      COMMAND jq ".extends = [\"${domain}\"]" "${CMAKE_BINARY_DIR}/${cog}/${cog}.json"
      OUTPUT_VARIABLE COG_JSON_CONTENT
    )
  endif()
  file(WRITE "${CMAKE_BINARY_DIR}/${cog}/${cog}.json" "${COG_JSON_CONTENT}")
endfunction()
