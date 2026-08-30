timeunit 1ns;
timeprecision 1ps;

module puf_monitor_probe (
    puf_core_if.mon_mp vif
);
    initial begin
        forever begin
            @(vif.mon_cb);
                $display(
                    "time=%0t rst_n=%0b start=%0b challenge=%0b busy=%0b ready=%0b",
                    $time,
                    vif.mon_cb.rst_n,
                    vif.mon_cb.start,
                    vif.mon_cb.challenge,
                    vif.mon_cb.busy,
                    vif.mon_cb.ready
                );
        end
    end
endmodule
