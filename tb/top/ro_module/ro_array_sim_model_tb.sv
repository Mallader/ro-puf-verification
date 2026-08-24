timeunit 1ns;
timeprecision 1ps;

module ro_array_sim_model_tb #(parameter int PROFILE = 0);

    localparam int NUM_RO           = 4;
    localparam int MAX_TEST_CYCLES  = 50;
    localparam int PROFILE_NORMAL   = 0;
    localparam int PROFILE_TIE_LAST = 1;
    localparam int PROFILE_CLOSE    = 2;

    localparam realtime HALF_PERIODS [NUM_RO] =
        (PROFILE == PROFILE_NORMAL)   ? '{4ns, 5ns, 6ns, 7ns}   :
        (PROFILE == PROFILE_TIE_LAST) ? '{4ns, 5ns, 7ns, 7ns}   :
        (PROFILE == PROFILE_CLOSE)    ? '{4ns, 5ns, 6ns, 6.2ns} :
                                        '{4ns, 5ns, 6ns, 7ns};


    logic [NUM_RO-1:0] ro_clk;

    logic clk27 = 1'b0;
    always #5 clk27 = ~clk27;


    ro_array_sim_model #(.NUM_RO(NUM_RO), .HALF_PERIODS(HALF_PERIODS)) ro_array_sim (
        .ro_clk(ro_clk)
    );

    initial begin
        $timeformat(-9, 1, " ns", 0);
    end

    initial begin  

        if (PROFILE == PROFILE_NORMAL)
            $display("RO PROFILE: NORMAL");
        else if (PROFILE == PROFILE_TIE_LAST)
            $display("RO PROFILE: TIE_LAST");
        else if (PROFILE == PROFILE_CLOSE)
            $display("RO PROFILE: CLOSE");
        else
            $fatal(1, "Unsupported RO PROFILE: %0d", PROFILE);

        fork : test
            begin : measurements
                for (int i = 0; i < NUM_RO; i++) begin
                    automatic int idx = i;
                    fork
                        measure_ro(idx, HALF_PERIODS[idx]);
                    join_none
                end
                wait fork;
            end
            begin : timeout
                repeat (MAX_TEST_CYCLES) @(posedge clk27);
                $fatal(1, "TEST TIMEOUT");
            end
        join_any

        disable test;

        $display("RO ARRAY SIM MODEL TEST PASSED");
        $finish;
    end

    task automatic measure_ro(input int ro_index, realtime half_period);
        realtime current_time    = 0;
        realtime previous_time   = 0;
        realtime measured_period [0:3] = '{0, 0, 0, 0};
        realtime period = half_period * 2;

        for (int i = 0; i < 4; i++) begin
            @(posedge ro_clk[ro_index]);
            previous_time = current_time;
            current_time  = $realtime;
            measured_period[i] = current_time - previous_time;
        end

        if (realtime_equal(measured_period[1], period) &&
            realtime_equal(measured_period[2], period) &&
            realtime_equal(measured_period[3], period))
            $display("RO period = %0t : PASS", period);
        else
            $fatal(1, "RO period != %0t : FAIL; periods: %0t, %0t, %0t", period, measured_period[1], measured_period[2], measured_period[3]);

    endtask

    function automatic bit realtime_equal(
        realtime a,
        realtime b,
        realtime tolerance = 1ps
    );
        realtime diff;

        diff = a - b;

        if (diff < 0)
            diff = -diff;

        return diff <= tolerance;
    endfunction

endmodule
