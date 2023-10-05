// Definicion de la interfaz del bus y la fifo

interface bus_if #(parameter drvrs=16, parameter pckg_sz=16, parameter bits=1)(input bit clk);
	bit rst;
	bit pndng[bits-1:0][drvrs-1:0];
	bit pop[bits-1:0][drvrs-1:0];
	bit push[bits-1:0][drvrs-1:0];
	bit [pckg_sz-1:0] D_push[bits-1:0][drvrs-1:0];
    bit [pckg_sz-1:0] D_pop[bits-1:0][drvrs-1:0];
endinterface



// Definicion del tipo de transacciones posibles

// Transaccion del test al agent_generator (pk1)

typedef enum{aleatorios,genericos,broadcast,incorrecta,tamano,cantidad,multiple,cerosunos,ceros,unos,reset} tipo_trans;

// Transaccion del test al scoreboard (pk2)
typedef enum{reporte_comp, retar_prom, bw_prom} solicitud_sb; // Solictud al scoreboard

// Transaccion al BUS (pck4) (pck4)
class trans_bus #(parameter pckg_sz=16); //Esta transferencia se usa en el (pck3), (pck4)
	randc int retardo; // Tiempo en ciclos de clk antes de ejecutar la transaccion
	rand bit[pckg_sz-9:0] dato; // Dato de la transaccion
	int tiempo; // Tiempo de simulacion en la que se ejecuta la transaccion
	tipo_trans tipo; // Prueba
	randc int DRIVERS;
	int numero;
	int max_retardo;
	randc logic[7:0] Rx; // Dispositivo destino		*** int destino ***
	randc int Tx;         // Dispositivo origen 		*** int origen  ***
    bit [pckg_sz-1:0] D_push;   
	bit [pckg_sz-1:0] D_pop;

	constraint const_retardo{retardo<max_retardo; retardo>0;}
       	constraint const_dispositivos{DRIVERS<16; DRIVERS>3;}
       	constraint const_origen{Tx<16; Tx>=0;}
       	constraint const_destino{Rx<16; Rx>=0; Rx != Tx;}
	
	function new(int nm=4, int ret=1, int max_ret = 20, bit[pckg_sz-9:0] dto=0, int tmp=0, tipo_trans tpo=aleatorios, rx=0, tx=0);
		this.numero       = nm;
		this.retardo      = ret;
		this.max_retardo  = max_ret;
		this.dato         = dto;
		this.tiempo       = tmp;
		this.tipo         = tpo;
		this.Rx           = rx;
		this.Tx           = tx;
	endfunction
	
	function void print(string tag="");
		$display("[%g] %s Tiempo=%g Num=%g Tipo de transaccion=%s Retardo=%g Dato=0x%h Term Destino=%g  Term Origen=%g",
		$time,tag,tiempo,this.numero,this.tipo,this.retardo,this.dato,this.Rx,this.Tx);
	endfunction
endclass

// Transaccion del checker al scoreboard (pk5)
class trans_sb #(parameter pckg_sz=16);
	bit [pckg_sz-1:0] dato_enviado;
	int push_time;
	int pop_time;
	bit completado;
	bit reset;
	int latencia;
	int Rx;
	int Tx;

	function clean();
		this.dato_enviado = 0;
		this.push_time    = 0;
		this.pop_time     = 0;
		this.completado   = 0;
		this.reset        = 0;
		this.latencia     = 0;
		this.Rx           = 0;
		this.Tx           = 0;
	endfunction

	task calc_latencia;
		this.latencia = this.pop_time - this.push_time;
	endtask

	function print(string tag);
		$diaplay("[%g] %s Dato=%h, time_push=%g, time_pop=%g, completado=%g, rst=%g, latencia=%g Rx=%g Tx=%g",
			$time, tag, 
			this.dato_enviando,
			this.push_time,
			this.pop_time,
			this.completado,
			this.reset,
			this.latencia,
			this.Rx,
			this.Tx);
	endfunction
endclass

// Definicion de los mailboxes con cada paquete especifico
typedef mailbox #(tipo_trans)   tst_agnt_mbx;       
typedef mailbox #(solicitud_sb) tst_sb_mbx;  
typedef mailbox #(trans_bus)    trans_bus_mbx;  