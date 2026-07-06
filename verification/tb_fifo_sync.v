// =============================================================================
// Testbench: tb_fifo_sync
// Covers: fill to full, drain to empty, simultaneous read+write, reset mid-op
// Week 2 goal: all of the below pass before moving on to the async FIFO
//
// NOTE: this testbench samples outputs #1 after each posedge, not exactly at
// the posedge. This is deliberate: DUT registers update via non-blocking
// assignment (<=) in the NBA region of the same simulation time step, so
// reading them in the same Active-region statement as the clock edge is a
// classic race condition. Waiting #1 lets the NBA update settle first.
// This exact issue is a common real-world verification gotcha, worth
// understanding rather than just copying the pattern.
// =============================================================================

`timescale 1ns/1ps

module tb_fifo_sync;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 4;   // small depth so full/empty are easy to hit

    reg                     clk;
    reg                     rst_n;
    reg                     wr_en;
    reg  [DATA_WIDTH-1:0]   wr_data;
    wire                    full;
    reg                     rd_en;
    wire [DATA_WIDTH-1:0]   rd_data;
    wire                    empty;

    integer errors = 0;

    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .full(full),
        .rd_en(rd_en), .rd_data(rd_data), .empty(empty)
    );

    // 10ns clock period
    always #5 clk = ~clk;

    // Advance one clock edge and let NBA updates settle before returning
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check(input cond, input [255:0] msg);
        begin
            if (!cond) begin
                $display("[FAIL] %0t: %0s", $time, msg);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0t: %0s", $time, msg);
            end
        end
    endtask

    initial begin
        $dumpfile("fifo_sync.vcd");
        $dumpvars(0, tb_fifo_sync);

        // Init
        clk = 0; rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 0;
        tick(); tick();
        rst_n = 1;
        tick();

        // --- Test 1: empty flag on reset ---
        check(empty == 1, "FIFO should be empty immediately after reset");
        check(full  == 0, "FIFO should not be full immediately after reset");

        // --- Test 2: fill to full ---
        wr_en = 1;
        repeat (DEPTH) begin
            wr_data = wr_data + 1'b1;   // writes 1,2,3,4 on consecutive cycles
            tick();
        end
        wr_en = 0;
        check(full == 1, "FIFO should be full after writing DEPTH items");

        // --- Test 3: writing while full should NOT corrupt data (write ignored) ---
        wr_en = 1; wr_data = 8'hFF;
        tick();
        wr_en = 0;
        check(full == 1, "FIFO should still report full (overflow write ignored)");

        // --- Test 4: drain to empty, check FIFO ordering (FIFO not LIFO) ---
        rd_en = 1;
        tick(); check(rd_data == 8'h01, "First read should return first value written (0x01)");
        tick(); check(rd_data == 8'h02, "Second read should return second value written (0x02)");
        tick(); check(rd_data == 8'h03, "Third read should return third value written (0x03)");
        tick(); check(rd_data == 8'h04, "Fourth read should return fourth value written (0x04)");
        rd_en = 0;
        tick();
        check(empty == 1, "FIFO should be empty after draining all items");

        // --- Test 5: reading while empty should not corrupt state ---
        rd_en = 1;
        tick();
        rd_en = 0;
        check(empty == 1, "FIFO should still report empty (underflow read ignored)");

        // --- Test 6: simultaneous read+write when neither full nor empty ---
        wr_en = 1; wr_data = 8'hAA;
        tick();
        wr_en = 0;
        // exactly one item (0xAA) in FIFO now; do simultaneous write+read
        wr_en = 1; rd_en = 1; wr_data = 8'hBB;
        tick();
        wr_en = 0; rd_en = 0;
        check(rd_data == 8'hAA, "Simultaneous read+write: should read the item written earlier (0xAA)");
        check(empty == 0, "FIFO should have exactly one item left (0xBB) after simultaneous op");

        // --- Test 7: reset mid-operation clears pointers ---
        rst_n = 0;
        tick();
        rst_n = 1;
        tick();
        check(empty == 1, "FIFO should be empty immediately after a mid-operation reset");

        // --- Summary ---
        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===\n");
        else
            $display("\n=== %0d TEST(S) FAILED ===\n", errors);

        $finish;
    end

endmodule
