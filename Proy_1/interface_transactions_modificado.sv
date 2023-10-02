//////////////////////////////////////////////////////////////
// Definición del tipo de transacciones posibles en el bus //
//////////////////////////////////////////////////////////////

typedef enum {cant_transac, cant_disp, rst_test, alea_ret, transac_error, aleat_brdst, alt_transac, simul_transac, random_rst} instruct; 

/////////////////////////////////////////////////////////////////////////////////////////
//Transacción: este objeto representa las transacciones que entran y salen del bus. //
/////////////////////////////////////////////////////////////////////////////////////////
class trans_bus #(parameter pckg_sz = 32, parameter drvrs=5);
  rand bit [pckg_sz-13:0] informacion; //20 bits de informacion
  rand int retardo; // tiempo de retardo en ciclos de reloj que se debe esperar antes de ejecutar la transacción
  rand bit[pckg_sz-1:0] dato; // este es el dato de la transacción
  int tiempo; //Representa el tiempo  de la simulación de envio 
  instruct tipo; // lectura, escritura, broadcast, reset;
  int max_retardo;
  bit [3:0] Tx;
  bit [7:0] Rx;

 
  //constraint
  constraint const_retardo {retardo <= max_retardo; retardo>0;}
  constraint const_Rx {Rx < drvrs; Rx >= 0; Rx != Tx;}
  constraint const_Tx {Tx < drvrs; Tx >= 0;}

  function new(bit [pckg_sz-19:0] info=0, int ret =0,bit[pckg_sz-1:0] dto=0,int tmp = 0, instruct tpo = cant_transac, int mx_rtrd = 20, tx = 0, rx = 0);
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
    this.Tx = tx;
    this.Rx = rx;
    this.informacion = info;
  endfunction
  
  function clean;
    this.retardo = 0;
    this.dato = 0;
    this.tiempo = 0;
    this.tipo = cant_transac;
    this.Tx = 0;
    this.Rx = 0;
    this.informacion=0;
  endfunction
    
  function void print(string tag = "");
    $display("[%g] %s Tiempo de envio=%g Tipo=%s Retardo=%g Transmisor=0x%h dato=0x%h Receptor=0x%h",$time,tag,tiempo,this.tipo,this.retardo,this.Tx,this.dato,this.Rx);
  endfunction

endclass

////////////////////////////////////////////////////////////////
// Interface: Esta es la interface que se conecta con el Bus  //
////////////////////////////////////////////////////////////////

interface bus_if #(parameter bits = 1,parameter drvrs = 4, parameter pckg_sz = 16, parameter broadcast = {8{1'b1}}) (
  input bit clk
);
  logic rst;
  logic pndng[bits-1:0][drvrs-1:0];
  logic push[bits-1:0][drvrs-1:0];
  logic pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] Data_pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push[bits-1:0][drvrs-1:0];
endinterface

////////////////////////////////////////////////
// Objeto de transacción usado en el monitor  //
////////////////////////////////////////////////

class trans_monitor #(parameter pckg_sz = 32);
  bit[pckg_sz-1:0] dato; // este es el dato de la transacción
  int tiempo; //Representa el tiempo  de la simulación en el que se ejecutó la transacción 
  bit [7:0] Rx;

  function new(bit[pckg_sz-1:0] dto=0,int tmp = 0, int rx= 0);
    this.dato = dto;
    this.tiempo = tmp;
    this.Rx = rx;
  endfunction
  

    
  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g dato=0x%h Receptor=0x%h",$time,tag,tiempo,this.dato,this.Rx);
  endfunction

endclass

////////////////////////////////////////////////////
// Objeto de transacción usado en el scroreboard  //
////////////////////////////////////////////////////

//Aún no

///////////////////////////////////////////////////////////////////////////////////////
// Definicion de mailboxes de tipo definido intruct para comunicar las interfaces //
///////////////////////////////////////////////////////////////////////////////////////

//typedef mailbox #(instruct) comando_instrucciones_mbx;

 

//typedef mailbox #(trans_monitor #(.pckg_sz(pckg_sz))) cmd_mnt_chk_mbx;


