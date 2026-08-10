# ============================================================
# run.do — GUI-запуск SystemVerilog testbench в QuestaSim
#
# Запуск из Transcript:
#   cd C:/work/PUF_verification/tb/sim
#   do run.do
# ============================================================

transcript on

# -------------------- НАСТРОЙКИ ТЕСТА ------------------------

# Имя верхнего module
set TOP puf_core_if_modport_tb

# package/interface должны идти раньше модулей, которые их используют;
# верхний testbench обычно компилируется последним.
set SRC_FILES [list \
    ../top/puf_checker_probe.sv \
    ../top/puf_core_model.sv \
    ../top/puf_driver_probe.sv \
    ../top/puf_monitor_probe.sv \
    ../interfaces/puf_core_if.sv \
    ../top/puf_core_if_tb.sv \
]

set WORK_LIB work

# 1 — пересоздавать work при каждом запуске.
set CLEAN_WORK 1

# 1 — добавить все сигналы в Wave.
set ADD_ALL_WAVES 1

# -------------------- ПОДГОТОВКА -----------------------------

puts ""
puts "============================================================"
puts "Starting test: $TOP"
puts "Working directory: [pwd]"
puts "============================================================"

# Выгрузить предыдущую модель, не закрывая Questa.
catch {quit -sim}

if {$CLEAN_WORK && [file exists $WORK_LIB]} {
    puts "Deleting old library: $WORK_LIB"
    vdel -lib $WORK_LIB -all
}

if {![file exists $WORK_LIB]} {
    puts "Creating library: $WORK_LIB"
    vlib $WORK_LIB
}

vmap $WORK_LIB $WORK_LIB

# -------------------- КОМПИЛЯЦИЯ -----------------------------

foreach src $SRC_FILES {
    if {![file exists $src]} {
        puts ""
        puts "ERROR: source file not found:"
        puts "  $src"
        puts "Current directory:"
        puts "  [pwd]"
        return
    }

    puts "Compiling: $src"
    vlog -work $WORK_LIB -sv $src
}

# -------------------- ЗАГРУЗКА -------------------------------

puts "Loading: ${WORK_LIB}.${TOP}"

# $finish завершает тест, но окно Questa остаётся открытым.
# +acc сохраняет доступ к внутренним сигналам для Wave.
vsim -onfinish stop -voptargs=+acc ${WORK_LIB}.${TOP}

# -------------------- WAVE -----------------------------------

if {$ADD_ALL_WAVES} {
    add wave -r /*
    radix hexadecimal
}

# -------------------- ЗАПУСК ---------------------------------

run -all

puts ""
puts "============================================================"
puts "Simulation finished: $TOP"
puts "Questa remains open because -onfinish stop is enabled."
puts "To rerun without recompilation:"
puts "  restart -f"
puts "  run -all"
puts "============================================================"
