module apb_master(apb_interface apb_if);

    always_ff @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
        if (!apb_if.PRESETn) begin
            apb_if.PSEL    <= 1'b0;
            apb_if.PENABLE <= 1'b0;
            apb_if.PWRITE  <= 1'b0;
            apb_if.PADDR   <= 32'b0;
            apb_if.PWDATA  <= 32'b0;
        end
    end

    task write(input logic [31:0] waddr, input logic [31:0] wdata); 
        $display("[APB_MASTER] Write request: addr=0x%08h, data=%0d", waddr, wdata);

        @(posedge apb_if.PCLK iff !apb_if.PREADY);
        apb_if.PSEL    = 1'b1;   
        apb_if.PENABLE = 1'b0;  
        apb_if.PWRITE  = 1'b1;   
        apb_if.PADDR   = waddr; 
        apb_if.PWDATA  = wdata; 

        @(posedge apb_if.PCLK); 
        apb_if.PENABLE = 1'b1;     

        @(posedge apb_if.PCLK iff apb_if.PREADY); 
        
        apb_if.PSEL    = 1'b0;   
        apb_if.PENABLE = 1'b0;    
        if (apb_if.PSLVERR) $display("[APB_MASTER] ERROR WRITE");
        else $display("[APB_MASTER] Write completed.\n"); 
    endtask

    task read(input logic [31:0] raddr);
        logic [31:0] rdata;
        @(posedge apb_if.PCLK iff !apb_if.PREADY);
        apb_if.PSEL    = 1'b1;    
        apb_if.PENABLE = 1'b0;    
        apb_if.PWRITE  = 1'b0;  
        apb_if.PADDR   = raddr;
        $display("[APB_MASTER] READ from addr: %2h", raddr);

        @(posedge apb_if.PCLK); 
        apb_if.PENABLE = 1'b1;

        @(posedge apb_if.PCLK iff apb_if.PREADY);
        if (apb_if.PSLVERR) begin
            $display("[APB_MASTER] ERROR READ\n");
        end else begin
            @(posedge apb_if.PCLK);
            rdata = apb_if.PRDATA; 
            $display("[APB_MASTER] Read completed.");
            $display("[APB_MASTER] READ: rdata = %0d (0x%08h)\n", rdata[31:0], rdata[31:0]);
        end

        apb_if.PSEL    = 1'b0;   
        apb_if.PENABLE = 1'b0;  
    endtask 
   
 endmodule

