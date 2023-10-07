//Definicion de estructura para los diferentes test

typedef enum {trans_aleat, broadcast, trans_each, trans_retarmin, trans_spec} inst_agnt;
typedef enum { reporte_promedio, reporte_bwmax, reporte_bwmin, reporte_transacciones} reporte;

//Definicion de estructuras


//Transaccion de agente a driver y driver a checker
class trans_bus #(parameter width=32, parameter n_term=5);
 	rand bit [width-13:0] info; //Dato ramdomizado
	rand int retardo; //Retardo de envio
	int tiempo; //Tiempo de envio
	rand bit [3:0] term_envio; //terminal donde se envia
	rand bit [7:0] term_recibo; //terminal donde se recibe
	int retard_max; //retardo maximo
	inst_agnt tipo; //tipo de test a realizar
	bit [width-1:0] dato; //Dato que se concatena con terminal de envio e info
	

	//constraints
        constraint const_retardo{retardo<=retard_max;retardo>0;}
	constraint const_term_rec {term_recibo<n_term;term_recibo>=0;term_recibo!=term_envio;}
	constraint const_term_env {term_envio<n_term;term_envio>=0;}


	function new(bit [width-19:0] inf=0, int rtd=0, int tmp=0, int rtd_max=0, inst_agnt tp=trans_aleat, bit [width-1:0] dt=0, bit [3:0] trm_env=0, bit [7:0] trm_rcb=0);

		this.info = inf;
		this.retardo = rtd;
		this.tiempo = tmp;
		this.retard_max = rtd_max;
		this.tipo = tp;
		this.dato = dt;
		this.term_envio = trm_env;
		this.term_recibo = trm_rcb;
	endfunction

	function void print (string ms = "");
      $display("[%g] %s Tipo=%s Retardo=%g dato=%h terminal de envio=%g terminal de recibo=%g", 
		$time, 
		ms, 
		this.tipo,
		this.retardo, 
		this.dato, 
		this.term_envio, 
		this.term_recibo);
	endfunction
endclass

//Transaccion de checker a scoreboard
class trans_scb #(parameter width=32);
	
	bit [width-1:0] dato_recibido; //dato recibido
	bit [width-1:0] dato_enviado; //dato enviado
	int tiempo_envio; //tiempo de envio
	int tiempo_recibo; //tiempo recibido
	int latencia; //latencia entre envio y recibido
	inst_agnt tipo; //tipo de test
	int term_envio; //terminal de envio
	int term_recibo; //terminal de recibido


	task calc_latencia;
		this.latencia = this.tiempo_recibo-this.tiempo_envio ;
	endtask

	function void print (string tag = "");
		$display("[%g] %s dt_rcb= %h dt_env=%h tpo=%s term_env=%g term_rcb=%g",
			$time, 
			tag,
			this.dato_recibido, 
			this.dato_enviado,  
			this.tipo,
			this.term_envio, 
			this.term_recibo);
	endfunction

endclass


//Transaccion saliente de monitor al checker
class trans_monitor #(parameter width=32);

	bit [width-1:0] dato;//dato recibido
   	int tiempo;//dato enviado
  	int terminal_recibo;//dato recibido
	
  function new(bit [width-1:0] dt=0, int tmp=0, int term_rcb=0);
	this.dato=dt;
    	this.tiempo=tmp;
    	this.terminal_recibo=term_rcb;
	endfunction

	function void print (string tag="");
      $display("[%g] %s dato=%h tiempo=%g term_rcb=%g", 
      		$time,
		tag, 
		this.dato, 
		this.tiempo, 
		this.terminal_recibo);
	endfunction

endclass
//Definicion de mailboxes

typedef mailbox #(inst_agnt) comando_tst_agnt_mbx; //mailbox de test a agent
typedef mailbox #(trans_bus #(.width(width),.n_term(n_term))) comando_agnt_drv_mbx; //mailbox de agent a driver
typedef mailbox #(trans_bus#(.width(width),.n_term(n_term))) comando_drv_chk_mbx;  //mailbox de driver a checker
typedef mailbox #(trans_scb #(.width(width))) comando_chk_scb_mbx;  //mailbox de checker a scoreboard
typedef mailbox #(trans_bus #(.width(width),.n_term(n_term))) comando_drv_child_mbx; //mailbox de drivers a checker
typedef mailbox #(trans_monitor #(.width(width))) comando_mnt_chk_mbx; //mailbox de monitor a cheker
typedef mailbox #(reporte) comando_rpt_mbx; //mailbox de test a scoreboard

//Definicion de interfaces

//Interface entre driver/monitor y DUT
interface switch_if #(parameter width=32, parameter bits=1, parameter n_term=5)(input bit clk);
  logic rst[n_term];
  logic pndng[bits-1:0][n_term-1:0];
  logic pop[bits-1:0][n_term-1:0];
  logic push[bits-1:0][n_term-1:0];
  logic [width-1:0] D_push[bits-1:0][n_term-1:0];
  logic [width-1:0] D_pop[bits-1:0][n_term-1:0];
endinterface
