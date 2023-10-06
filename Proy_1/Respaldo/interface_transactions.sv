// Interfase, transacciones y mailbox
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: Genera la interface para facilitar las conexiones entre modulos.
// Genera los diferentes tipos de transacciones necesarios para las pruebas. 
// Se definen los mailbox.

//////////////////////////////////////////////////////////////////////
// Definición de tipo de variables para las instrucciones y reporte //
//////////////////////////////////////////////////////////////////////

//Crea nuevo tipo de dato para intrucciones con nombres especifico, para intrucciones y reporte
typedef enum {trans_aleat, broadcast, trans_each, trans_retarmin, trans_spec, num_trans_aleat} instruct; 
typedef enum {rpt_prom, rpt_bw_max, rpt_bw_min, rpt_transac} reporte; 


/////////////////////////////////////////////////////////////////////////////
//Transacción: este objeto representa las transacciones que entran al bus. //
/////////////////////////////////////////////////////////////////////////////

class trans_bus #(parameter pckg_sz = 32, parameter drvrs=5);
  rand bit [pckg_sz-13:0] informacion; // Corresponde al payload (aletorio)
  rand int retardo; // tiempo de retardo (aleatorio) antes de ejecutar la transacción
  int tiempo; // Representa el tiempo de la simulación de envio
  rand bit [3:0] dato_env; // De donde se envia
  rand bit [7:0] dato_rec; // De donde se recibe
  int max_retardo; // Limite de retardo
  instruct tipo; // Tipo de prueba a realizar
  bit[pckg_sz-1:0] dato; // Este corresponde al paquete/transacción que se envia
  
  
  // Constraint
  constraint const_retardo {retardo <= max_retardo; retardo>0;} // Limita el retardo para que sea controlado
  constraint const_dato_rec {dato_rec < drvrs; dato_rec >= 0; dato_rec != dato_env;} // Limita direcciones de recibido según la cantidad de drvrs
  constraint const_dato_env {dato_env < drvrs; dato_env >= 0;} // Limita direcciones de envio según la cantidad de drvrs

  // Constructor que inicializa la intancia de la clase
  function new(bit [pckg_sz-19:0] info=0, int ret =0,bit[pckg_sz-1:0] dto=0,int tmp = 0, instruct tpo = trans_aleat, int mx_rtrd = 20, bit [3:0] tx = 0, bit [7:0] rx = 0);
    this. informacion = info;
    this.retardo = ret;
    this.dato = dto;
    this.tiempo = tmp;
    this.tipo = tpo;
    this.max_retardo = mx_rtrd;
    this.dato_env = tx;
    this.dato_rec = rx;
  endfunction

    // Método para limpiar la transacción
  function clean();
    this.informacion = 0;
    this.retardo = 0;
    this.dato = 0;
    this.tipo = trans_aleat;
    this.dato_env = 0;
    this.dato_rec = 0;
  endfunction
  
  // Método se utiliza para imprimir información sobre la transacción
  function void print(string tag = "");
    $display("[%g] %s Tiempo de envio=%g Tipo=%s Retardo=%g Transmisor=0x%h Dato=0x%h Receptor=0x%h",
              $time,tag, this.tiempo, this.tipo,this.retardo,this.dato_env,this.dato,this.dato_rec);
  endfunction

endclass

////////////////////////////////////////////////
// Objeto de transacción usado en el monitor  //
////////////////////////////////////////////////

class trans_monitor #(parameter pckg_sz = 32);
  bit[pckg_sz-1:0] dato; // Este es el dato de la transacción recibida
  int tiempo; // Tiempo de la simulación en el que se ejecutó la transacción 
  bit [7:0] dato_rec_mnt; // Dirección que recibe

  // Constructor que inicializa la intancia de la clase
  function new(bit[pckg_sz-1:0] dto=0,int tmp = 0, int rx_mnt= 0);
    this.dato = dto;
    this.tiempo = tmp;
    this.dato_rec_mnt = rx_mnt;
  endfunction

  // Método para limpiar la transacción
  function clean();
    this.dato = 0;
    this.tiempo = 0;
    this.dato_rec_mnt = 0;
  endfunction

  // Método se utiliza para imprimir información sobre la transacción
  function void print(string tag = "");
    $display("[%g] %s Tiempo=%g Dato=0x%h Receptor=0x%h",
              $time,tag,this.dato,this.tiempo,this.dato_rec_mnt);
  endfunction

endclass



////////////////////////////////////////////////////
// Objeto de transacción usado en el scoreboard  //
////////////////////////////////////////////////////

class trans_sb #(parameter pckg_sz=32); 
  bit [pckg_sz-1:0] dato_env; // Dato que envio el agente
  bit [pckg_sz-1:0] dato_rec; // Dato que recibio el monitor
  int tiempo_env; // Tiempo en que se envio
  int tiempo_rec; // Tiempo en que se recibio
  int laten; // Latencia de la transacción
  instruct tipo; // Intrucción que ejecuta
  int dev_env; // Dispositivo de donde se envia
  int dev_rec; // Dispositivo que recibe

  

  // Método para limpiar la transacción
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

  // Calcula latencia en base a los tiempos
  task calc_laten;
    this.laten = this.tiempo_rec - this.tiempo_env;
  endtask
  
  // Método se utiliza para imprimir información sobre la transacción
  function print (string tag);
    $display("[%g] %s dato_env=%h,dato_rec=%h,t_env=%g,t_rec=%g,ltncy=%g,tipo=%g,term_env=%g,term_rec=%g",  
             $time, tag, this.dato_env, this.dato_rec, this.tiempo_env, this.tiempo_rec, this.laten, this.tipo, this.dev_env, this.dato_rec);
  endfunction
endclass


////////////////////////////////////////////////////////////////
// Interface: Esta es la interface que se conecta con el Bus  //
////////////////////////////////////////////////////////////////

// La interfaces seran las mismas entradas y salidas de DUT
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

////////////////////////////////////////////////////////////////////////////////////
// Definicion de mailboxes de tipo definido intruct para comunicar las interfaces //
////////////////////////////////////////////////////////////////////////////////////

typedef mailbox #(instruct) tam;                                    // Mail Box test - agente
typedef mailbox #(reporte) rm;                                      // Mail Box reporte
typedef mailbox #(trans_bus#(.pckg_sz(pckg_sz),.drvrs(drvrs))) adm; // Mail Box agente - driver
typedef mailbox #(trans_bus#(.pckg_sz(pckg_sz),.drvrs(drvrs))) dcm; // Mail Box driver - checker
typedef mailbox #(trans_bus#(.pckg_sz(pckg_sz),.drvrs(drvrs))) DCHM;// Mail Box diver child
typedef mailbox #(trans_monitor#(.pckg_sz(pckg_sz))) mcm;           // Mail Box de monitor a checker
typedef mailbox #(trans_sb#(.pckg_sz(pckg_sz))) csm;                // Mail Box checker - scoreboard


