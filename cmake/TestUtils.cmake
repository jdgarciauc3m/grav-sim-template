# TestUtils.cmake - Common utilities for unit test targets

function(add_unit_test_target)
  # Parse arguments
  cmake_parse_arguments(
    PARSED_ARGS
    ""
    "TARGET_NAME;LIBRARY_FILTER;COVERAGE_DIR;LIBRARY_TO_LINK"
    "SOURCE_FILES;INCLUDE_DIRS"
    ${ARGN}
  )

  # Validate required arguments
  if(NOT PARSED_ARGS_TARGET_NAME)
    message(FATAL_ERROR "TARGET_NAME is required")
  endif()
  
  if(NOT PARSED_ARGS_SOURCE_FILES)
    message(FATAL_ERROR "SOURCE_FILES is required")
  endif()
  
  if(NOT PARSED_ARGS_LIBRARY_FILTER)
    message(FATAL_ERROR "LIBRARY_FILTER is required for coverage")
  endif()
  
  # Set defaults
  if(NOT PARSED_ARGS_COVERAGE_DIR)
    set(PARSED_ARGS_COVERAGE_DIR "coverage-${PARSED_ARGS_TARGET_NAME}")
  endif()
  
  if(NOT PARSED_ARGS_LIBRARY_TO_LINK)
    set(PARSED_ARGS_LIBRARY_TO_LINK "common")
  endif()
  
  # Create the test executable
  add_executable(${PARSED_ARGS_TARGET_NAME})
  
  # Add source files
  target_sources(${PARSED_ARGS_TARGET_NAME} PRIVATE
    ${PARSED_ARGS_SOURCE_FILES}
  )
  
  # Link libraries
  target_link_libraries(${PARSED_ARGS_TARGET_NAME} 
    PRIVATE 
    ${PARSED_ARGS_LIBRARY_TO_LINK}
    Microsoft.GSL::GSL
    gtest_main
    gtest
  )
  
  # Add include directories if specified
  if(PARSED_ARGS_INCLUDE_DIRS)
    target_include_directories(${PARSED_ARGS_TARGET_NAME} PRIVATE
      ${PARSED_ARGS_INCLUDE_DIRS}
    )
  endif()
  
  # Discover and register tests with CTest
  gtest_discover_tests(${PARSED_ARGS_TARGET_NAME})
  
  set(COVERAGE_SUPPORTED OFF)
  if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang)$")
    set(COVERAGE_SUPPORTED ON)

    # Add coverage flags (Cleaned up: --coverage handles compiler & linker instrumentation)
    target_compile_options(${PARSED_ARGS_TARGET_NAME} PRIVATE
      --coverage
      -O0
      -g
    )

    target_link_options(${PARSED_ARGS_TARGET_NAME} PRIVATE
      --coverage
    )
  endif()
  
  # Locate gcovr
  find_program(GCOVR_EXECUTABLE gcovr)
  
  if(COVERAGE_SUPPORTED AND GCOVR_EXECUTABLE)
    set(COVERAGE_TARGET "coverage-${PARSED_ARGS_TARGET_NAME}")
    set(COVERAGE_CLEAN_TARGET "coverage-${PARSED_ARGS_TARGET_NAME}-clean")
    set(COVERAGE_CLEAN_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${PARSED_ARGS_TARGET_NAME}-coverage-clean.cmake")

    file(GENERATE OUTPUT "${COVERAGE_CLEAN_SCRIPT}" CONTENT
"file(GLOB_RECURSE COVERAGE_DATA_FILES \"${CMAKE_BINARY_DIR}/*.gcda\")\n\
if(COVERAGE_DATA_FILES)\n\
  file(REMOVE \${COVERAGE_DATA_FILES})\n\
endif()\n"
    )
    
    # Coverage target that runs tests and generates reports
    add_custom_target(${COVERAGE_TARGET}
      COMMAND ${CMAKE_COMMAND} -E echo "Running ${PARSED_ARGS_TARGET_NAME} tests to generate coverage data..."
      COMMAND $<TARGET_FILE:${PARSED_ARGS_TARGET_NAME}>
      COMMAND ${CMAKE_COMMAND} -E echo "Generating ${PARSED_ARGS_TARGET_NAME} coverage reports..."
      COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_BINARY_DIR}/${PARSED_ARGS_COVERAGE_DIR}
      
      # HTML Report (Fixed: removed invalid --condition flag)
      COMMAND ${GCOVR_EXECUTABLE} --html --html-details 
              -o ${CMAKE_BINARY_DIR}/${PARSED_ARGS_COVERAGE_DIR}/coverage_report.html
              --root ${CMAKE_SOURCE_DIR}
              --filter "${PARSED_ARGS_LIBRARY_FILTER}/"
              --exclude "out/"
              --exclude-unreachable-branches
              --exclude-throw-branches
              --html-theme green
              --print-summary
              
      # XML Report (Fixed: removed invalid --condition flag)
      COMMAND ${GCOVR_EXECUTABLE} --xml 
              -o ${CMAKE_BINARY_DIR}/${PARSED_ARGS_COVERAGE_DIR}/coverage_report.xml
              --root ${CMAKE_SOURCE_DIR}
              --filter "${PARSED_ARGS_LIBRARY_FILTER}/"
              --exclude "out/"
              
      # TXT Report (Fixed: replaced --condition with --txt-metric condition)
      COMMAND ${GCOVR_EXECUTABLE} --txt 
              -o ${CMAKE_BINARY_DIR}/${PARSED_ARGS_COVERAGE_DIR}/coverage_report.txt
              --root ${CMAKE_SOURCE_DIR}
              --filter "${PARSED_ARGS_LIBRARY_FILTER}/"
              --exclude "out/"
              --txt-metric branch
              --txt-metric decision
              
      COMMAND ${CMAKE_COMMAND} -E echo "${PARSED_ARGS_TARGET_NAME} coverage reports generated in ${CMAKE_BINARY_DIR}/${PARSED_ARGS_COVERAGE_DIR}/"
      DEPENDS ${PARSED_ARGS_TARGET_NAME}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      COMMENT "Generating coverage reports for ${PARSED_ARGS_TARGET_NAME}"
    )
    
    # Coverage clean target (Fixed: portable CMake removal commands)
    add_custom_target(${COVERAGE_CLEAN_TARGET}
      COMMAND ${CMAKE_COMMAND} -E echo "Cleaning ${PARSED_ARGS_TARGET_NAME} coverage data..."
      COMMAND ${CMAKE_COMMAND} -E rm -rf ${CMAKE_BINARY_DIR}/${PARSED_ARGS_COVERAGE_DIR}
      COMMAND ${CMAKE_COMMAND} -P ${COVERAGE_CLEAN_SCRIPT}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      COMMENT "Cleaning ${PARSED_ARGS_TARGET_NAME} coverage data files"
    )
    
  elseif(NOT COVERAGE_SUPPORTED)
    message(STATUS "Coverage targets for ${PARSED_ARGS_TARGET_NAME} are only available with GCC/Clang-compatible compilers.")
  else()
    message(WARNING "gcovr not found. Coverage targets for ${PARSED_ARGS_TARGET_NAME} will not be available.")
  endif()

endfunction()