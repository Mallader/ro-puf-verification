# Run in the Questa Transcript:
#   cd C:/work/PUF_verification/tb/sim
#   do run_puf_core_proc_tb.do
# Or, from any directory:
#   source C:/work/PUF_verification/tb/sim/run_puf_core_proc_tb.do
# The test runs in a child console process of the same Questa installation.
# Its files are deleted after that process exits; the calling GUI stays open.
# Test output is printed in Transcript. Rerun this script to repeat the test.

set script_dir [file dirname [file normalize [info script]]]
# Questa's "do" command may leave [info script] empty.
if {![file exists [file join $script_dir run_puf_core_proc_tb.do]]} {
    set script_dir [file normalize [pwd]]
    if {![file exists [file join $script_dir run_puf_core_proc_tb.do]]} {
        error "Use source <full-path>/run_puf_core_proc_tb.do, or cd to tb/sim before do."
    }
}

proc run_puf_core_proc_tb {script_dir} {
    set script_dir [file normalize $script_dir]
    set top puf_core_tb
    set tb_dir [file normalize [file join $script_dir ..]]
    set rtl_dir [file normalize [file join $tb_dir .. ring_oscillator]]
    set sources [list \
        [file join $tb_dir interfaces puf_core_if.sv] \
        [file join $rtl_dir gate_timer.sv] \
        [file join $rtl_dir cdc_sync.sv] \
        [file join $rtl_dir ro_counter.sv] \
        [file join $rtl_dir snapshot.sv] \
        [file join $rtl_dir ro_pair_measure.sv] \
        [file join $rtl_dir challenge_mapper.sv] \
        [file join $rtl_dir puf_fsm.sv] \
        [file join $rtl_dir response_builder.sv] \
        [file join $tb_dir top ro_module ro_array_sim_model.sv] \
        [file join $tb_dir top puf_core puf_core.sv] \
        [file join $tb_dir top puf_core puf_core_dut_wrapper.sv] \
        [file join $tb_dir top puf_core puf_core_driver.sv] \
        [file join $tb_dir top puf_core puf_core_monitor.sv] \
        [file join $tb_dir top puf_core puf_core_checker.sv] \
        [file join $tb_dir top puf_core puf_core_tb.sv] \
    ]
    foreach src $sources {
        if {![file isfile $src]} {
            error "Required source file does not exist: $src"
        }
    }

    # clock clicks is not a unique ID. Keep existing files/directories intact
    # and select a free suffix, including after an interrupted earlier run.
    set run_prefix .puf_core_proc_tmp_[pid]_[clock clicks]
    for {set suffix 0} {1} {incr suffix} {
        set run_dir [file normalize [file join $script_dir ${run_prefix}_$suffix]]
        set run_parent [file dirname $run_dir]
        if {$::tcl_platform(platform) eq "windows"} {
            set same_parent [string equal -nocase $run_parent $script_dir]
        } else {
            set same_parent [string equal $run_parent $script_dir]
        }
        # Only a new directory directly inside script_dir may be removed later.
        if {!$same_parent} {
            error "Unsafe temporary directory: parent '$run_parent', expected '$script_dir'"
        }
        if {![file exists $run_dir]} {
            break
        }
    }

    set simulator [file join [file dirname [info nameofexecutable]] vsim.exe]
    if {![file isfile $simulator]} {
        error "Cannot find the Questa executable: $simulator"
    }

    catch {quit -sim}
    # Keep output in the Transcript pane without creating a transcript file.
    transcript file ""
    transcript on
    file mkdir $run_dir

    set failed [catch {
        set worker_file [file join $run_dir simulate.do]
        set worker [open $worker_file w]
        puts $worker [list set sources $sources]
        puts $worker [list set top $top]
        puts $worker [list cd $run_dir]
        puts $worker {
            onerror {quit -f -code 1}
            onbreak {resume}
            set failed [catch {
                set work_lib [file join [pwd] work]
                vlib $work_lib
                # Physical paths do not change the user's modelsim.ini.
                foreach src $sources {
                    vlog -sv -work $work_lib $src
                }
                # Match run_ro_module_sim.do: preserve debug visibility.
                # Without +acc, this test crashes Questa 2024.1 in GUI mode.
                vsim -lib $work_lib -onfinish stop -voptargs=+acc \
                    -wlf [file join [pwd] vsim.wlf] -wlfdeleteonquit $top
                run -all
                set status [runStatus -full]
                if {$status ne {break simulation_stop {$finish}}} {
                    error "Test failed with simulator status '$status'."
                }
            } message]
            if {$failed} {
                puts "ERROR: $message"
                quit -f -code 1
            }
            # Only the child exits. This also releases GUI/library-manager
            # handles that quit -sim alone does not release on Windows.
            quit -f -code 0
        }
        close $worker
        unset worker

        puts "Starting $top (default PROFILE=0) in a Questa console process..."
        exec $simulator -c -l [file join $run_dir transcript] \
            -do [list do $worker_file] 2>@1
    } message options]

    # exec has waited for the child to exit. No design library was loaded in
    # this GUI, so all files can now be removed without retained GUI handles.
    if {[info exists worker]} {
        catch {close $worker}
    }
    puts $message
    set cleanup_failed [catch {
        file delete -force -- $run_dir
    } cleanup_message]
    if {$cleanup_failed} {
        puts "ERROR: Cleanup failed for $run_dir: $cleanup_message"
    }
    if {$failed} {
        error "Simulation failed; see the Questa output above."
    }
    if {$cleanup_failed} {
        error $cleanup_message
    }
    puts "PASSED: $top. Temporary files deleted; Questa remains open."
}

run_puf_core_proc_tb $script_dir
