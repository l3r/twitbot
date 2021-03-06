find_package(EOSIO REQUIRED)
find_package(Wasm REQUIRED)
find_package(Binaryen REQUIRED)

macro(add_wast_target target)
    include_directories(${EOSIO_INCLUDE_DIRS})

    foreach(item "${ARGN}")
        string(REGEX MATCH ".+\\.cpp" item ${item})
        if(item)
            list(APPEND Sources ${item})
        endif(item)
    endforeach()

    set(list_var "${Sources}")
    foreach(srcfile IN LISTS list_var)
        add_custom_command(OUTPUT ${srcfile}.bc
            DEPENDS ${ARGN}
            COMMAND ${WASM_CLANG} -emit-llvm -O3 --std=c++14 --target=wasm32 -ffreestanding
            -nostdlib -fno-threadsafe-statics -fno-rtti -fno-exceptions
            "-I$<JOIN:$<TARGET_PROPERTY:${target},INCLUDE_DIRECTORIES>,;-I>"
            -c "${CMAKE_CURRENT_SOURCE_DIR}/${srcfile}" -o ${srcfile}.bc
            IMPLICIT_DEPENDS CXX "${CMAKE_CURRENT_SOURCE_DIR}/${srcfile}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMAND_EXPAND_LISTS)
        set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${srcfile}.bc)
        list(APPEND outfiles ${srcfile}.bc)
    endforeach()

    add_custom_command(OUTPUT ${target}.wast
        DEPENDS ${outfiles}
        COMMAND ${WASM_LLVM_LINK} -o ${target}.bc ${outfiles}
        COMMAND ${WASM_LLC} -asm-verbose=false -o ${target}.s ${target}.bc
        COMMAND ${BINARYEN_BIN} -o ${target}.wast -s 1024 ${target}.s
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM)
    set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES
        ${srcfile}.bc
        ${target}.bc
        ${target}.s
        ${target}.wast)

    add_custom_target(${target} ALL DEPENDS ${target}.wast SOURCES ${ARGN})
endmacro()

macro(target_generate_abi target header)
    add_custom_command(TARGET ${target}
        POST_BUILD
        COMMAND ${EOSIO_ABI_GEN} -extra-arg=-c -extra-arg=--std=c++14 -extra-arg=--target=wasm32
        -extra-arg=-I${EOSIO_INCLUDE_DIRS}  -extra-arg=-I${CMAKE_CURRENT_BINARY_DIR}
        -extra-arg=-fparse-all-comments -destination-file=${target}.abi -verbose=0
        -context=${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${header} --
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endmacro()
