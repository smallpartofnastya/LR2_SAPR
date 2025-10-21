module apb_slave(apb_interface apb_if);

    logic [31:0] operand1_reg;
    logic [31:0] operand2_reg;
    logic [1:0]  control_reg;
    logic [31:0] result_reg;



    always_ff @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
        if (!apb_if.PRESETn) begin
            apb_if.PREADY  <= 1'b0; 
            apb_if.PSLVERR <= 1'b0;
            operand1_reg   <= 32'b0;
            operand2_reg   <= 32'b0;
            control_reg    <= 2'b0;
            result_reg     <= 32'b0;
        end else begin
            apb_if.PSLVERR <= 1'b0;

            // WRITE operation
            if (apb_if.PSEL && apb_if.PENABLE && apb_if.PWRITE && !apb_if.PREADY) begin
                if (apb_if.PADDR!=32'h0 && apb_if.PADDR!=32'h4 &&
                    apb_if.PADDR!=32'h8 && apb_if.PADDR!=32'hC) begin
                    $display("[APB_SLAVE] ERROR: addr isn't in range");
                    apb_if.PSLVERR <= 1'b1;
                    apb_if.PREADY  <= 1'b1;
                end else begin
                    case (apb_if.PADDR)
                        32'h0: begin
                            operand1_reg <= apb_if.PWDATA;
                            $display("[APB_SLAVE] Write operand1: %0d", apb_if.PWDATA);
                        end
                        32'h4: begin
                            operand2_reg <= apb_if.PWDATA;
                            $display("[APB_SLAVE] Write operand2: %0d", apb_if.PWDATA);
                        end
                        32'h8: begin
                            control_reg <= apb_if.PWDATA[1:0];
                            $display("[APB_SLAVE] Write control: 0x%0h", apb_if.PWDATA[1:0]);
                        end
                        32'hC: begin
                            $display("[APB_SLAVE] ERROR: WRITE to read-only result register");
                            apb_if.PSLVERR <= 1'b1;
                        end
                    endcase

                    if (!apb_if.PSLVERR) begin
                        case (control_reg)
                            2'b01: result_reg <= operand1_reg & operand2_reg;
                            2'b10: result_reg <= operand1_reg | operand2_reg;
                            2'b11: result_reg <= operand1_reg ^ operand2_reg;
                            default: result_reg <= 32'b0;
                        endcase
                    end

                    apb_if.PREADY <= 1'b1;
                end // valid address
            end // WRITE

            
            // READ operation
            else if (apb_if.PSEL && apb_if.PENABLE && !apb_if.PWRITE && !apb_if.PREADY) begin
		if (apb_if.PADDR!=32'h0 && apb_if.PADDR!=32'h4 &&
                    apb_if.PADDR!=32'h8 && apb_if.PADDR!=32'hC) begin
                    $display("[APB_SLAVE] ERROR: addr isn't in range");
                    apb_if.PSLVERR <= 1'b1;
                    apb_if.PREADY  <= 1'b1;
                    apb_if.PRDATA  <= 32'hDEAD_BEEF;
                end else begin
                    case (apb_if.PADDR)
                        32'h0: apb_if.PRDATA <= operand1_reg;
                        32'h4: apb_if.PRDATA <= operand2_reg;
                        32'h8: apb_if.PRDATA[1:0] <= control_reg;
                        32'hC: apb_if.PRDATA <= result_reg;
                    endcase

                    if (!apb_if.PSLVERR)
                        $display("[APB_SLAVE] Read from %02h", apb_if.PADDR);

                    apb_if.PREADY <= 1'b1;
                end // valid address
            end // READ

            if (!apb_if.PSEL)
                apb_if.PREADY <= 1'b0;

        end // else reset
    end // always_ff

endmodule

