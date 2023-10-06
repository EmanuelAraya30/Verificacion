////////////////////////////////////////////////////////////////////////////
// Definición del tipo de transacciones posibles en el bus y sus reportes //
////////////////////////////////////////////////////////////////////////////

typedef enum {trans_aleat, broadcast, trans_each, trans_retarmin, trans_spec} instruct; 
typedef enum {rpt_prom, rpt_bw_max, rpt_bw_min, rpt_transac} reporte; 


/////////////////////////////////////////////////////////////////////////////////////////
//Transacción: este objeto representa las transacciones que entran y salen del bus. //
/////////////////////////////////////////////////////////////////////////////////////////
class trans_bus #(parameter pckg_sz = 32, parameter drvrs=5);
  rand bit [pckg_sz-13:0] informacion; //20 bits de informacion
  rand int retardo; // tiempo de retardo en ciclos de reloj que se debe esperar antes de ejecutar la transacción
  int tiempo; //Representa el tiempo  de la simulación de envio
  rand bit [3:0] dato_env;
  rand bit [7:0] dato_rec;
  int max_retardo;
  instruct tipo; // lectura, escritura, broadcast, reset;
  bit[pckg_sz-1:0] dato; // este es el dato de la transacción 
  
  
  

 
  //constraint
  constraint const_retardo {retardo <= max_retardo; retardo>0;}
  constraint const_Rx {Rx < drvrs; Rx >= 0; Rx != Tx;}
  constraint const_Tx {Tx < drvrs; Tx >= 0;}

  function new(bit [pckg_sz-19:0] info=0, int ret =0,bit[pckg_sz-1:0] dto=0,int tmp = 0, instruct tpo = trans_aleat, int mx_rtrd = 20, bit [3:0] tx = 0, bit [7:0] rx = 0);
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
    this.Tx = tx;
    this.Rx = rx;
    this.informacion = info;
  endfunction
  
    
  function void print(string tag = "");
    $display("[%g] %s Tiempo de envio=%g Tipo=%s Retardo=%g Transmisor=0x%h dato=0x%h Receptor=0x%h",$time,tag,this.tipo,this.retardo,this.Tx,this.dato,this.Rx);
  endfunction

endclass

////////////////////////////////////////////////////////////////
// Interface: Esta es la interface que se conecta con el Bus  //
////////////////////////////////////////////////////////////////


////////////////////////////////////////////////
// Objeto de transacción usado en el monitor  //
////////////////////////////////////////////////


////////////////////////////////////////////////////
// Objeto de transacción usado en el scoreboard  //
////////////////////////////////////////////////////

class trans_sb #(parameter pckg_sz=16);
  bit [pckg_sz-1:0] dato_env; //Tx
  bit [pckg_sz-1:0] dato_rec; //Rx
  int tiempo_env;
  int tiempo_rec;
  int laten;
  instruct tipo;
  int dev_env;
  int dev_rec;

  
  function clean();
    this.dato_env = 0;
    this.dato_rec = 0;
    this.tiempo_env = 0;
    this.tiempo_rec = 0;
    this.laten = 0;
    this.tipo = trans_aleat;
    this.dev_env = 0;
    this.dev_rec = 0;
  endfunction

  task calc_laten;
    this.laten = this.tiempo_rec - this.tiempo_env;
  endtask
  
  function print (string tag);
    $display("[%g] %s dato_env=%h,dato_rec=%h,t_env=%g,t_rec=%g,ltncy=%g,tipo=%g,term_env=%g,term_rec=%g", 
             $time,
             tag, 
             this.dato_env, 
             this.dato_rec,              
             this.tiempo_env,
             this.tiempo_rec,
             this.laten,
             this.tipo,
             this.dev_env,
             this.dato_rec
             );
  endfunction
endclass


class trans_monitor #(parameter pckg_sz = 32);
  bit[pckg_sz-1:0] dato; // este es el dato de la transacción
  int tiempo; //Representa el tiempo  de la simulación en el que se ejecutó la transacción 
  bit [7:0] Rx_mnt;

  function new(bit[pckg_sz-1:0] dto=0,int tmp = 0, int rx_mnt= 0);
    this.dato = dto;
    this.tiempo = tmp;
    this.Rx_mnt = rx_mnt;
  endfunction
  

    
  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g dato=0x%h Receptor=0x%h",$time,tag,this.dato,this.tiempo,this.Rx_mnt);
  endfunction

endclass


////////////////////////////////////////////////////////////////////////////////////
// Definicion de mailboxes de tipo definido intruct para comunicar las interfaces //
////////////////////////////////////////////////////////////////////////////////////


typedef mailbox #(instruct) tam;
typedef mailbox #(trans_bus) adm;
typedef mailbox #(trans_bus) dcm;
typedef mailbox #(trans_sb) csm;
typedef mailbox #(trans_bus ) DCHM; 
typedef mailbox #(trans_monitor) mcm;  //mailbox de monitor a checker
typedef mailbox #(reporte) rm;


interface bus_if #(parameter bits = 1,parameter drvrs = 4, parameter pckg_sz = 16, parameter broadcast = {8{1'b1}}) (
  input bit clk
);
  logic rst [drvrs];
  logic pndng[bits-1:0][drvrs-1:0];
  logic push[bits-1:0][drvrs-1:0];
  logic pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] Data_pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push[bits-1:0][drvrs-1:0];
endinterface
