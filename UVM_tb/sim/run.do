# Resolve source paths relative to this script, regardless of the launch directory.
cd [file dirname [file normalize [info script]]]

onerror {if {[batch_mode]} {quit -f -code 1} else {abort}}
onbreak {if {[batch_mode]} {quit -f -code 1} else {abort}}

if {![file exists work]} {
    vlib work
}

vlog -sv -work work -f sources.f

vsim -onfinish stop work.top
run -all

if {[batch_mode]} {
    quit -f -code 0
}
