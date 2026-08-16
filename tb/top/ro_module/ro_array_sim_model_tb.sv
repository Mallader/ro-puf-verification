timeunit 1ns;
timeprecision 1ps;

module ro_array_sim_model_tb;

    localparam int NUM_RO      = 4;
    localparam MAX_TEST_CYCLES = 50;

    logic [NUM_RO-1:0] ro_clk;

    logic clk27 = 1'b0;

    always #5 clk27 = ~clk27;


    ro_array_sim_model #(.NUM_RO(NUM_RO)) ro_array_sim (
        .ro_clk(ro_clk)
    );

    initial begin
        $timeformat(-9, 0, " ns", 0);
    end

    initial begin
        fork
            fork
                measure_ro(0, 8);
                measure_ro(1, 10);
                measure_ro(2, 12);
                measure_ro(3, 14);
            join
            begin
                repeat (MAX_TEST_CYCLES) @(posedge clk27);
                $fatal(1, "TEST TIMEOUT");
            end
        join_any

        $display("RO ARRAY SIM MODEL TEST PASSED");
        $finish;
    end

    task automatic measure_ro(int ro_index, time period);
        time current_time    = 0;
        time previous_time   = 0;
        time measured_period [0:3] = '{0, 0, 0, 0};

        for (int i = 0; i < 4; i++) begin
            @(posedge ro_clk[ro_index]);
            previous_time = current_time;
            current_time  = $time;
            measured_period[i] = current_time - previous_time;
        end

        if ((measured_period[1] == period) &&
            (measured_period[2] == period) &&
            (measured_period[3] == period))
            $display("RO period = %0t : PASS", period);
        else
            $fatal(1, "RO period != %0t : FAIL", period);

    endtask

endmodule
