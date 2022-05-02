################################################################################
# EXCLUDE_FROM_ALL in root CMakeLists.txt, but we NEED it for install

# typically: ABC_LIBS : -lreadline;-lpthread;-lm;-ldl;-lrt
message(WARNING "extract_var : ABC_LIBS : ${ABC_LIBS}")
# same as ABC_CXXFLAGS
message(WARNING "extract_var : ABC_CFLAGS : ${ABC_CFLAGS}")
# eg: -Wall;-Wno-unused-function;-Wno-write-strings;-Wno-sign-compare;-DLIN64;-DSIZEOF_VOID_P=8;-DSIZEOF_LONG=8;-DSIZEOF_INT=4;-DABC_USE_CUDD=1;-DABC_USE_READLINE;-DABC_USE_PTHREADS
message(WARNING "extract_var : ABC_CXXFLAGS : ${ABC_CXXFLAGS}")

set(LIB_ABC "libabc-pic")
set_target_properties(${LIB_ABC} PROPERTIES EXCLUDE_FROM_ALL OFF)

# TODO? ALTERNATIVE: custom target, that way deps are properly using CMake instead of raw flags
# and CPACK_DEBIAN_PACKAGE_SHLIBDEPS works?
# add_library(${LIB_ABC} ${ABC_SRC})

# set_property(TARGET ${LIB_ABC} PROPERTY OUTPUT_NAME abc2)

# target_include_directories(${LIB_ABC} PUBLIC ${PROJECT_SOURCE_DIR}/src)
# target_compile_options_filtered(${LIB_ABC} PUBLIC ${ABC_CFLAGS} ${ABC_CXXFLAGS} -Wno-unused-but-set-variable )

################################################################################
# "properly" handle the deps
# That way they will be set for the final .deb

# if("-lreadline" IN_LIST ABC_LIBS)
#     message(WARNING "extract_var : HAS_LREADLINE : ${HAS_LREADLINE}")
#         find_path(Readline_ROOT_DIR
#         NAMES include/readline/readline.h
#         REQUIRED
#     )

#     # Search for include directory
#     find_path(Readline_INCLUDE_DIR
#         NAMES readline/readline.h
#         HINTS ${Readline_ROOT_DIR}/include
#         REQUIRED
#     )

#     # Search for library
#     find_library(Readline_LIBRARY
#         NAMES readline
#         HINTS ${Readline_ROOT_DIR}/lib
#         REQUIRED
#     )

#     target_link_libraries(${LIB_ABC} PUBLIC ${Readline_LIBRARY})
#     target_include_directories(${LIB_ABC} PUBLIC ${Readline_INCLUDE_DIR})
# endif()


################################################################################
# default to only DEB
option(CPACK_BINARY_DEB "<help_text>" ON)
option(CPACK_BINARY_STGZ "<help_text>" OFF)
option(CPACK_BINARY_TBZ2 "<help_text>" OFF)
option(CPACK_BINARY_TGZ "<help_text>" OFF)
option(CPACK_BINARY_TZ "<help_text>" OFF)
option(CPACK_BINARY_ZIP "<help_text>" OFF)

install(TARGETS ${LIB_ABC} LIBRARY DESTINATION lib)
# DO NOT remove, without this CPACK_DEBIAN_PACKAGE_SHLIBDEPS found no dep??
# "CPackDeb Debug: Using only user-provided depends because package does not
#   contain executable files that link to shared libraries."
install(TARGETS abc RUNTIME DESTINATION bin)

set(CPACK_PACKAGE_CONTACT "dev@interstellar.gg")
set(CPACK_STRIP_FILES ON)
# "A good package should list its dependencies. This can be turned on with the following variable:"
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS YES)
set(CPACK_DEBIAN_PACKAGE_DEBUG ON)

include(CPack)

cpack_add_component(applications
  DISPLAY_NAME "ABC Application"
  DESCRIPTION
   "ABC executable"
  GROUP Runtime)
cpack_add_component(libraries
  DISPLAY_NAME "ABC library: libabc-pic"
  DESCRIPTION
  "ABC library"
  GROUP Development)
cpack_add_component(headers
  DISPLAY_NAME "C++ Headers"
  DESCRIPTION "C/C++ header files for use with libabc"
  GROUP Development
  DEPENDS libraries
  )