module apb_slave(apb_interface apb_if);

    logic [31:0] operand1_reg;
    logic [31:0] operand2_reg;
    logic [1:0]  control_reg;
    logic [31:0] result_reg;

    logic trans_done;

    always_ff @(posedge apb_if.PCLK or negedge apb_if.PRESETn) begin
        if (!apb_if.PRESETn) begin
            apb_if.PREADY  <= 1'b0; 
            apb_if.PSLVERR <= 1'b0;
            operand1_reg   <= 32'b0;
            operand2_reg   <= 32'b0;
            control_reg    <= 2'b0;
            result_reg     <= 32'b0;
            apb_if.PRDATA  <= 32'b0;
            trans_done     <= 1'b0;
        end else begin
            apb_if.PSLVERR <= 1'b0;

            if (!apb_if.PSEL) begin
                trans_done <= 1'b0;
                apb_if.PREADY <= 1'b0;
            end
	    if (apb_if.PSEL && apb_if.PENABLE && apb_if.PWRITE && trans_done) begin
		case (control_reg)
                        2'b01: result_reg <= operand1_reg & operand2_reg; // AND
                        2'b10: result_reg <= operand1_reg | operand2_reg; // OR
                        2'b11: result_reg <= operand1_reg ^ operand2_reg; // XOR
                        default: result_reg <= 32'b0;
                    endcase
                    apb_if.PREADY <= 1'b1;
	    end
            // WRITE
            if (apb_if.PSEL && apb_if.PENABLE && apb_if.PWRITE && !trans_done) begin
                case (apb_if.PADDR)
                        32'h0: begin
                            operand1_reg <= apb_if.PWDATA;
                            $display("[APB_SLAVE] Write operand1: %0d (0x%08h)", apb_if.PWDATA, apb_if.PWDATA);
                        end
                        32'h4: begin
                            operand2_reg <= apb_if.PWDATA;
                            $display("[APB_SLAVE] Write operand2: %0d (0x%08h)", apb_if.PWDATA, apb_if.PWDATA);
                        end
                        32'h8: begin
                            control_reg <= apb_if.PWDATA[1:0];
                            $display("[APB_SLAVE] Write control: 0x%0h", apb_if.PWDATA[1:0]);
                        end
			32'hC: begin
			    $display("[APB_SLAVE] ERROR: WRITE to read-only result register (0x%08h)", apb_if.PADDR);
                    	    apb_if.PSLVERR <= 1'b1;
                    	    apb_if.PREADY  <= 1'b1;
               		end 
 			default: begin
			    $display("[APB_SLAVE] ERROR: addr isn't in range (0x%08h)", apb_if.PADDR);
                    	    apb_if.PSLVERR <= 1'b1;
                            apb_if.PREADY  <= 1'b1;
                        end
                    endcase
              trans_done <= 1'b1; 
            end // WRITE

            // READ 
            else if (apb_if.PSEL && apb_if.PENABLE && !apb_if.PWRITE && !trans_done) begin
               case (apb_if.PADDR)
                        32'h0: apb_if.PRDATA <= operand1_reg;
                        32'h4: apb_if.PRDATA <= operand2_reg;
                        32'h8: apb_if.PRDATA <= {30'd0, control_reg};
                        32'hC: apb_if.PRDATA <= result_reg;
			default: begin
                    		$display("[APB_SLAVE] ERROR: addr isn't in range (0x%08h)", apb_if.PADDR);
                    		apb_if.PSLVERR <= 1'b1;
                    		apb_if.PRDATA  <= 32'hDEAD_BEEF;
                    		apb_if.PREADY  <= 1'b1;
			end
                    endcase

                    $display("[APB_SLAVE] Read from 0x%02h", apb_if.PADDR);
                    apb_if.PREADY <= 1'b1;
                trans_done <= 1'b1;
            end // READ

        end // else not reset
    end // always_ff

endmodule

