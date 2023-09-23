//////////////////////////////////////////////////////////////
// Definición del tipo de transacciones posibles en el bus //
//////////////////////////////////////////////////////////////

typedef enum {cant_transac, cant_disp, rst_test, alea_ret, transac_error, aleat_brdst, alt_transac, simul_transac, random_rst} instruct; 

/////////////////////////////////////////////////////////////////////////////////////////
//Transacción: este objeto representa las transacciones que entran y salen del bus. //
/////////////////////////////////////////////////////////////////////////////////////////
class trans_bus #(parameter pckg_sz = 32, parameter drvrs=5);
  rand int retardo; // tiempo de retardo en ciclos de reloj que se debe esperar antes de ejecutar la transacción
  rand bit[pckg_sz-1:0] dato; // este es el dato de la transacción
  int tiempo; //Representa el tiempo  de la simulación en el que se ejecutó la transacción 
  instruct tipo; // lectura, escritura, broadcast, reset;
  int max_retardo;
  int [3:0] Tx;
  int [7:0] Rx;

 
  //constraint
  constraint const_retardo {retardo <= max_retardo; retardo>0;}
  constraint const_Rx {Rx < drvrs; Rx >= 0; Rx != Tx;}
  constraint const_Tx {Tx < drvrs; Tx >= 0}

  function new(int ret =0,bit[pckg_sz-1:0] dto=0,int tmp = 0, instruct tpo = cant_transac, int mx_rtrd = 20, tx, rx);
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
    this.Tx = tx;
    this.Rx = rx;
  endfunction
  
  function clean;
    this.retardo = 0;
    this.dato = 0;
    this.tiempo = 0;
    this.tipo = cant_transac;
    this.Tx = 0;
    this.Rx = 0;
  endfunction
    
  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g Tipo=%s Retardo=%g Transmisor=0x%h dato=0x%h Receptor=0x%h",$time,tag,tiempo,this.tipo,this.retardo,this.Tx,this.dato,this.Rx);
  endfunction

endclass

////////////////////////////////////////////////////////////////
// Interface: Esta es la interface que se conecta con el Bus  //
////////////////////////////////////////////////////////////////

interface bus_if #(parameter bits = 1,parameter drvrs = 4, parameter pckg_sz = 16, parameter broadcast = {8{1'b1}}) (
  input bit clk
);
  logic reset;
  logic pndng[bits-1:0][drvrs-1:0];
  logic push[bits-1:0][drvrs-1:0];
  logic pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push[bits-1:0][drvrs-1:0];
endinterface

////////////////////////////////////////////////////
// Objeto de transacción usado en el scroreboard  //
////////////////////////////////////////////////////

//Aún no

///////////////////////////////////////////////////////////////////////////////////////
// Definicion de mailboxes de tipo definido intruct para comunicar las interfaces //
///////////////////////////////////////////////////////////////////////////////////////

typedef mailbox #(instruct) comando_instrucciones_mbx;