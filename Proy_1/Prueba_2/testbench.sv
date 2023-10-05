`timescale 1ns/1ps
`include "Library.sv"
`include "interface_transactions.sv"
`include "driver.sv"
`include "monitor.sv"
//`include "checker.sv"
//`include "scoreboard.sv"
`include "agent_generator.sv"
`include "environment.sv"
`include "test.sv" 

// Modulo del testbench
module tb;
	reg clk;
	parameter pckg_sz = 16;    // Bits
	parameter profundidad = 8;     // Drivers conectados
	parameter paquete = 8;    // Tamano del paquete
	parameter broadcast = 255; // Broadcast 
	parameter drvrs = 16;   // Controladores
	parameter bits = 1;
	test #(.profundidad(profundidad), .pckg_sz(pckg_sz), .drvrs(drvrs), .bits(bits)) prueba1;
	bus_if #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) _if(.clk(clk));


	always #5 clk = ~clk;
	
	bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast)) uut(
		.clk(_if.clk),
		.reset(_if.rst),
		.pndng(_if.pndng),
		.push(_if.push),
		.pop(_if.pop),
		.D_pop(_if.D_pop),
		.D_push(_if.D_push));

	initial begin
		clk = 0;
		prueba1 = new();
		prueba1._if = _if;
		prueba1.const_num.constraint_mode(1);
		prueba1.randomize();
		prueba1.ambiente_inst.driver_inst.vif    = _if;
		prueba1.ambiente_inst.monitor_inst.vif   = _if;
		fork
			prueba1.run();
		join_none
	end

	always@(posedge clk)begin
		if ($time > 500)begin
			$display("Testbench: Se alcanza tiempo limite de la prueba");
			$finish;
		end
	end
endmodule

