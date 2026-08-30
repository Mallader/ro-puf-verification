
transcript on

# Запуск из любого каталога:
#   source C:/work/PUF_verification/tb/sim/run_ro_module_sim.do
#
# Команда Questa "do" не передаёт имя macro-файла в [info script].
# Поэтому для обычного "do" нужно сначала перейти в каталог скрипта:
#   cd C:/work/PUF_verification/tb/sim
#   do run_ro_module_sim.do

# -------------------- НАСТРОЙКИ ТЕСТА ------------------------

# Имя верхнего module
set TOP ro_pair_measure_tb

set TEST_PROFILES [list \
    [list NORMAL   0] \
    [list TIE_LAST 1] \
    [list CLOSE    2] \
]

set SCRIPT_FILE [file normalize [info script]]

if {[file tail $SCRIPT_FILE] eq "run_ro_module_sim.do"} {
    set SCRIPT_DIR [file dirname $SCRIPT_FILE]
} else {
    set SCRIPT_DIR [file normalize [pwd]]

    if {![file exists [file join $SCRIPT_DIR run_ro_module_sim.do]]} {
        error "Cannot determine the .do location. Use 'source <full-path>/run_ro_module_sim.do', or cd to tb/sim before 'do run_ro_module_sim.do'."
    }
}

set TB_DIR     [file normalize [file join $SCRIPT_DIR ..]]
set RTL_DIR    [file normalize [file join $SCRIPT_DIR .. .. ring_oscillator]]

# package/interface должны идти раньше модулей, которые их используют;
# верхний testbench обычно компилируется последним.
set SRC_FILES [list \
    [file join $TB_DIR interfaces ro_pair_measure_if.sv] \
    [file join $RTL_DIR gate_timer.sv] \
    [file join $RTL_DIR cdc_sync.sv] \
    [file join $RTL_DIR ro_counter.sv] \
    [file join $RTL_DIR snapshot.sv] \
    [file join $RTL_DIR ro_pair_measure.sv] \
    [file join $TB_DIR top ro_module ro_array_sim_model.sv] \
    [file join $TB_DIR top ro_module dut_wrapper.sv] \
    [file join $TB_DIR top ro_module ro_module_driver.sv] \
    [file join $TB_DIR top ro_module ro_module_checker.sv] \
    [file join $TB_DIR top ro_module ro_pair_measure_tb.sv] \
]

set WORK_LIB_PATH [file join $SCRIPT_DIR work]

# 1 — пересоздавать work при каждом запуске.
set CLEAN_WORK 1

# 1 — добавить все сигналы в Wave.
set ADD_ALL_WAVES 1

# -------------------- ПОДГОТОВКА -----------------------------

puts ""
puts "============================================================"
puts "Starting test: $TOP"
puts "Working directory: [pwd]"
puts "Script directory: $SCRIPT_DIR"
puts "============================================================"

# Выгрузить предыдущую модель, не закрывая Questa.
catch {quit -sim}

if {$CLEAN_WORK && [file exists $WORK_LIB_PATH]} {
    puts "Deleting old library: $WORK_LIB_PATH"
    vdel -lib $WORK_LIB_PATH -all
}

if {![file exists $WORK_LIB_PATH]} {
    puts "Creating library: $WORK_LIB_PATH"
    vlib $WORK_LIB_PATH
}

# -------------------- КОМПИЛЯЦИЯ -----------------------------

foreach src $SRC_FILES {
    if {![file exists $src]} {
        puts ""
        puts "ERROR: source file not found:"
        puts "  $src"
        error "Required source file does not exist: $src"
    }

    puts "Compiling: $src"
    vlog -work $WORK_LIB_PATH -sv $src
}

# -------------------- ЗАПУСК ПРОФИЛЕЙ -------------------------

foreach test_profile $TEST_PROFILES {
    lassign $test_profile profile_name profile_value

    catch {quit -sim}

    puts ""
    puts "============================================================"
    puts "Running profile: $profile_name (PROFILE=$profile_value)"
    puts "============================================================"

    # $finish завершает тест, но окно Questa остаётся открытым.
    # +acc сохраняет доступ к внутренним сигналам для Wave.
    vsim -lib $WORK_LIB_PATH \
         -onfinish stop \
         -voptargs=+acc \
         -gPROFILE=$profile_value \
         $TOP

    if {$ADD_ALL_WAVES} {
        add wave -r /*
        radix hexadecimal
    }

    set errors_before_run $error_count
    run -all

    if {$error_count > $errors_before_run} {
        error "Profile $profile_name failed; see the Questa transcript above."
    }

    puts "Profile $profile_name PASSED"
}

puts ""
puts "============================================================"
puts "All requested profiles PASSED: $TOP"
puts "The last profile remains loaded because -onfinish stop is enabled."
puts "To rerun the last profile without recompilation:"
puts "  restart -f"
puts "  run -all"
puts "============================================================"
