// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: Interface




////////////////////////////////////////////////////////////////////////////
// Definición del tipo de transacciones posibles en el bus y sus reportes //
////////////////////////////////////////////////////////////////////////////

typedef enum {transaccion_aleat, broadcast, trans_todos, retardo_min, trans_determinada} instruct; 
typedef enum {reporte_prom, reporte_bw_max, reporte_bw_min, reporte_transac} reporte; 


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
  constraint const_retardo {retardo <= max_retardo; retardo>0;} //Se definen los constraints para el retardo, los datos de envio y recibo
  constraint const_dato_rec {dato_rec < drvrs; dato_rec >= 0; dato_rec != dato_env;}
  constraint const_dato_env {dato_env < drvrs; dato_env >= 0;}

  function new(bit [pckg_sz-19:0] info=0, int ret =0,bit[pckg_sz-1:0] dto=0,int tmp = 0, instruct tpo = transaccion_aleat, int mx_rtrd = 20, bit [3:0] tx = 0, bit [7:0] rx = 0);
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
    this.dato_env = tx;
    this.dato_rec = rx;
    this.informacion = info;
  endfunction
  
    
  function void print(string tag="");
    $display("--------------------------------------------------------------");
    $display("BUS TRANSACCIONES");
    $display("--------------------------------------------------------------");

    $display("[%s]",tag);
		$display("Tiempo de envio = %g",  this.tiempo);
		$display("Tipo de instruccion = %s", this.tipo );
    $display("Retardo = %g", this.retardo );
    $display("Transmisor = %h", this.dato_env );
    $display("Dato a enviar = %h", this.dato);
    $display("Receptor = %h", this.dato_rec);
		$display("--------------------------------------------------------------");

    //$display("[%g] %s Tiempo de envio=%g Tipo=%s Retardo=%g Transmisor=0x%h dato=0x%h Receptor=0x%h",$time,tag, this.tiempo, this.tipo,this.retardo,this.dato_env,this.dato,this.dato_rec);
  endfunction

endclass




////////////////////////////////////////////////////
// Objeto de transacción usado en el scoreboard  //
////////////////////////////////////////////////////

class trans_sb #(parameter pckg_sz=32);
  bit [pckg_sz-1:0] dato_env; 
  bit [pckg_sz-1:0] dato_rec; 
  int tiempo_env;
  int tiempo_rec;
  int laten;
  instruct tipo;
  int dev_env;
  int dev_rec;

  task calc_laten;
    this.laten = this.tiempo_rec - this.tiempo_env;
  endtask
  
  function print (string tag);
    $display("--------------------------------------------------------------");
    $display("TRANSACCIONES SCOREBOARD");
    $display("--------------------------------------------------------------");
    $display("[%s]",tag);
		$display("Dato enviado       = %h", this.dato_env);
		$display("Dato recibido      = %h", this.dato_rec);
    $display("Tiempo de envio    = %g", this.tiempo_env );
    $display("Tiempo de recibido = %g", this.tiempo_rec );
    $display("Latencia transac   = %g", this.laten);
    $display("Tipo de instrucc   = %s", this.tipo);
    $display("Terminal de envio  = %g", this.dev_env );
    $display("Terminal de recibo = %g", this.dato_rec);
		$display("--------------------------------------------------------------");
    
  endfunction
endclass

////////////////////////////////////////////////
// Objeto de transacción usado en el monitor  //
////////////////////////////////////////////////


class trans_monitor #(parameter pckg_sz = 32);
  bit[pckg_sz-1:0] dato; // este es el dato de la transacción
  int tiempo; //Representa el tiempo  de la simulación en el que se ejecutó la transacción 
  bit [7:0] dato_rec_mnt;

  function new(bit[pckg_sz-1:0] dto=0,int tmp = 0, int rx_mnt= 0);
    this.dato = dto;
    this.tiempo = tmp;
    this.dato_rec_mnt = rx_mnt;
  endfunction
  

    
  function void print(string tag = "");
    $display("--------------------------------------------------------------");
    $display("TRANSACCIONES MONITOR");
    $display("--------------------------------------------------------------");
    $display(" Tiempo de simulacion          =[%g]", $time);
    $display("[%s]" ,tag);
		$display("Tiempo                         = %g", this.tiempo);
		$display("Dato                           = %h", this.dato);
    $display("Terminal receptora Scoreboard  = %h", this.dato_rec_mnt );
		$display("--------------------------------------------------------------");
    //$display("[%g] %s Tiempo=%g dato=0x%h Receptor=0x%h",$time,tag,this.dato,this.tiempo,this.dato_rec_mnt);
  endfunction

endclass


////////////////////////////////////////////////////////////////////////////////////
// Definicion de mailboxes de tipo definido intruct para comunicar las interfaces //
////////////////////////////////////////////////////////////////////////////////////


typedef mailbox #(instruct) tam;
typedef mailbox #(trans_bus#(.pckg_sz(pckg_sz),.drvrs(drvrs))) adm;
typedef mailbox #(trans_bus#(.pckg_sz(pckg_sz),.drvrs(drvrs))) dcm;
typedef mailbox #(trans_sb#(.pckg_sz(pckg_sz))) csm;
typedef mailbox #(trans_bus#(.pckg_sz(pckg_sz),.drvrs(drvrs))) DCHM; 
typedef mailbox #(trans_monitor#(.pckg_sz(pckg_sz))) mcm;  //mailbox de monitor a checker
typedef mailbox #(reporte) rm;


////////////////////////////////////////////////////////////////
// Interface: Esta es la interface que se conecta con el Bus  //
////////////////////////////////////////////////////////////////

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
