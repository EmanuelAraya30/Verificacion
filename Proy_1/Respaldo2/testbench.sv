

`ifndef PRMT
	parameter pckg_sz = 32;
  	parameter drvrs = 16;
`endif


`include "Library.sv"
`include "interface_transactions.sv"
`include "agente.sv"
`include "driver.sv"
`include "monitor.sv"
`include "checker.sv"
`include "scoreboard.sv"
`include "ambiente.sv"
`include "test.sv"


module tb;

    parameter bits=1;
  	parameter broadcast= {8{1'b1}};

	reg clk;
	always #5 clk=~clk;

	
  	test #(.pckg_sz(pckg_sz), .drvrs(drvrs), .bits(bits)) test_inst;
	bus_if #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs), .broadcast(broadcast)) vif(clk);
	
  bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz),.broadcast(broadcast)) uut(
        .clk(clk),
    	.reset(vif.rst[0]),
    	.pndng(vif.pndng),
        .push(vif.push),
        .pop(vif.pop),
        .D_pop(vif.Data_pop),
        .D_push(vif.D_push)
    );
	initial begin
		clk=0;
		test_inst=new();
      
		test_inst.ambiente_inst.vif=vif;

		fork
			test_inst.inicia();
		join_none

	end

	always@(posedge clk)begin
      if($time>10000000)begin
          $display("La prueba termino");
			$finish;
		end
	end
endmodule