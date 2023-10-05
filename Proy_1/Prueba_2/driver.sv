// Definición de la cola que simula la fifo a la interfase y y la la salida de conexion al dut 
class fifo #(parameter pckg_sz=16, parameter profundidad=8);
	bit [pckg_sz-1:0]Data_push;
	bit [pckg_sz-1:0]Data_pop;
	bit pndng;
    bit [pckg_sz-1:0] cola [$];

	task push(); // Task para hacer el push en la fifo simulada
		if (cola.size>profundidad) begin
			cola.push_back(Data_push);
			cola.delete(0);
		end
		else begin
			cola.push_back(Data_push);
		end
	endtask
	task pop(); // Task para hacer el push en la fifo simulada
		if (cola.size()!=0) begin
			Data_pop=cola.pop_front();
		end
	endtask
	task pending(); // Task para saber si hay datos en la cola  //Pending es de la tarea
		if(cola.size()!=0)begin
			pndng = 1;
		end
		else pndng = 0;
	endtask
endclass

class driver_hijo #(parameter drvrs=4, parameter pckg_sz=16, parameter profundidad=8, parameter bits=1);
	fifo #(.pckg_sz(pckg_sz), .profundidad(profundidad)) fifo_in;
	virtual bus_if #(.drvrs(drvrs), .profundidad(profundidad), .bits(bits)) vif;	
	trans_bus_mbx driver_h_mbx; // Mailbox del agente al driver de tipo trans_bus
	trans_bus #(.pckg_sz(pckg_sz)) transaction;	
	
	int retardo;
	logic [7:0] Rx;
	int Tx;
	bit [pckg_sz-1:0]dato;
	bit [pckg_sz-1:0]dato_out;
	int r;
	int dest = Rx;
	
	function new;
		fifo_in=new();
		driver_h_mbx=new();
		transaction=new();
		fifo_in.pndng=0;		
	endfunction

	task run();
		driver_h_mbx.peek(transaction);
		if (Tx == transaction.Tx)begin	
			$display("[%g] Driver: Cantidad de mensajes a enviar %g",$time,driver_h_mbx.num());
			driver_h_mbx.get(transaction);
			$display("--------------------------------------------------------------");
			$display("Driver Hijo #[%g]: Dispositivo %g listo para enviar",$time,Tx);
		
			vif.pndng[bits-1][Tx] <= 0;
			vif.D_pop[bits-1][Tx] <= 0;
			vif.rst    <= 1;
			#2 vif.rst <= 0;
			fifo_in.Data_push = transaction.Data_push;
			fifo_in.push();
			fifo_in.pending();

			r = 0;
			while (r < retardo)begin
				r++;
			end
				
	
			fifo_in.pop();
			vif.D_pop[bits-1][Tx] <= fifo_in.Data_pop;
			vif.pndng[bits-1][Tx] <= fifo_in.pndng;
			@(posedge vif.pop[bits-1][Tx]);
				$display("[%g] Se envio el mensaje",$time);		
				$display("[%g] D_pop = %b pndng = %b",$time,vif.D_pop[0][Tx],vif.pndng[0][Tx]);		
		end		
	endtask
endclass

class driver #(parameter pckg_sz=16, parameter profundidad=8, parameter drvrs=4, parameter bits=1); 
	virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz), .bits(bits)) vif;	
	driver_hijo #(.drvrs(drvrs),.pckg_sz(pckg_sz),.profundidad(profundidad),.bits(bits)) d_hijo_inst[drvrs-1:0];
	trans_bus_mbx agnt_drvr_mbx; // Mailbox del agente al driver de tipo trans_bus
	int espera;

	function new;
    		for (int i=0;i<drvrs; i++)begin
      			automatic int k=i;
      			fork
				d_hijo_inst[k]=new();
			join_none
    		end
  	endfunction

task run();
	$display("[%g] El driver fue inicializado",$time);
	forever begin
	#1
	
	for (int i=0; i<drvrs; i++)begin
      		automatic int k=i;
		d_hijo_inst[k].vif = vif;
		d_hijo_inst[k].driver_h_mbx = agnt_drvr_mbx;
		d_hijo_inst[k].Tx = k;
		d_hijo_inst[k].run();	
	end		
	end

endtask
endclass 

