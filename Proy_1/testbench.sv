`timescale 1ns/10ps
`default_nettype none
`include "interface_transactions.sv"
`include "fifo_driver.sv"
`include "library.sv"

module bus_tb;  
  //Definiendo parametros que recibe el testbench
  
  parameter bits = 1;
  parameter drvrs = 5;
  parameter pckg_sz = 16;
  parameter broadcast = {8{1'b1}};
  
  
  // Definiendo entradas del testbench
  reg clk_tb;
  reg reset_tb;
  reg pndng_tb [bits-1:0][drvrs-1:0];
  reg [pckg_sz-1:0] D_pop_tb [bits-1:0][drvrs-1:0] ;
  
  // Definiendo salidas del testbench
  
  reg push_tb [bits-1:0][drvrs-1:0];
  reg pop_tb [bits-1:0][drvrs-1:0];
  reg [pckg_sz-1:0] D_push_tb [bits-1:0][drvrs-1:0];
  
  // Data push y Data pop para el bus
  
  reg [pckg_sz-1:0] Data_pop_tb [bits-1:0][drvrs-1:0];
  
  
  
  //Hay que conectar la interfaz virtual al testbench y luego la interfaz virtual al
  // DUT, la interfaz sirve como "traductor" entre wl hardware y software
  
  
  bus_if  #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast)) bus_if_inst (.clk(clk_tb)); 
                                                                                               //.rst(reset_tb), .pndng(pndng_tb), .push(push_tb), .pop(pop_tb), .D_pop(D_pop_tb), .D_push(D_push_tb));
  
  
 //Conectando la interfaz y el DUT
  bs_gnrtr_n_rbtr #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz), .broadcast(broadcast)) Top_bus_inst (.clk(bus_if_inst.clk), .reset(bus_if_inst.rst), .pndng(bus_if_inst.pndng), .push(bus_if_inst.push), .pop(bus_if_inst.pop), .D_pop(bus_if_inst.Data_pop), .D_push(bus_if_inst.D_push));
  
  //Instanciando clases del Driver
  
  
  fifo_driver #(.bits(bits), .drvrs(drvrs), .pckg_sz(pckg_sz)) fifo_driver_inst;
  
  driver_hijo #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) driver_hijo_inst;
  
  driver_padre #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) driver_padre_inst;

initial begin
  $dumpfile("Intf.vcd");
  $dumpvars(0,bus_tb);
  $dumpvars(0);
end  
  
initial begin
forever begin
   #1 clk_tb = ~clk_tb; 
end
end
  
initial begin
  clk_tb =1;
  reset_tb=1;
  #2
  reset_tb =0;
  driver_padre_inst = new();
  for (int i=0; i<drvrs; i++)begin
    automatic int j = i;
    driver_padre_inst.driver_h[j].fifo_d.vif = bus_if_inst;
  end
  
  #10;
  driver_padre_inst.inicia();
  #100;
  
$finish;
  
end
  
endmodule
