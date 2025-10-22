`timescale 1ns/1ps
`include "apb_interface.sv"
`include "apb_master.sv"
`include "apb_slave.sv"

module tb_apb();
    logic clk, reset, rdata;
    apb_interface apb_if();

    initial begin
        clk = 0;
        reset = 0;
        #20 reset = 1;
        forever #5 clk = ~clk;
    end

    assign apb_if.PCLK = clk;
    assign apb_if.PRESETn = reset;

    apb_slave slave (apb_if.slave_mp);
    apb_master master (apb_if.master_mp);
    
    initial begin
	@(posedge reset);

        $display("\n=====[TEST 1] Write/read operands=====");
        master.write('h0, 32'hAAAAAAAA);
        master.read('h0);
        master.write('h4, 32'h0F0F0F0F);
        master.read('h4);

        $display("\n=====[TEST 2] AND operation (control=01)=====");
        master.write('h8, 32'd1);
        master.read('h8);
        master.read('hC);

        $display("\n=====[TEST 3] OR operation (control=10)=====");
        master.write('h8, 32'd2); 
        master.read('h8);
        master.read('hC);

        $display("\n=====[TEST 4] XOR operation (control=11)=====");
        master.write('h8, 32'd3); 
        master.read('h8);
        master.read('hC);

        $display("\n=====[TEST 5] Attempt to write read-only register=====");
        master.write('hC, 32'hDEAD_BEEF);

        $display("\n=====[TEST 6] Invalid address check=====");
        master.write('hFFFFFFFF, 32'h12345678);
        master.read('h10000000);

        $display("\n=====[TEST 7] Consecutive operations=====");
        master.write('h0, 32'h12345678);
        master.write('h4, 32'hFFFFFFFF);
        master.write('h8, 32'd1); 
        master.read('hC);
        master.write('h8, 32'd2); 
        master.read('hC);
        master.write('h8, 32'd3); 
        master.read('hC);

        $display("\n=====[TEST 8] Reset behavior after activity=====");
        reset = 0; #10; reset = 1;
        master.read('h0);
        master.read('h4);
        master.read('h8);
        master.read('hC);

        $display("\n====[TEST COMPLETED SUCCESSFULLY]====\n");
        #50;
        $finish;
    end

endmodule

