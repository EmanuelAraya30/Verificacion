class fifo_driver #(parameter pckg_sz = 32, parameter drvrs=5);
	bit push;
	bit pop;
	bit pending;
	bit [pckg_sz-1:0] Data_pop;
	bit [pckg_sz-1:0] fifo_queue [$];
	int ident;
	
	virtual bus_intf #(.pckg_sz(pckg_sz), .drvrs(drvrs)) vif;
	
	function new(int identify);
		this.push = 0;
		this.pop = 0;
		this.pending = 0;
		this.Data_pop = 0;
		this.ident = identify;
	endfunction 
	
	
	task pen_update(); //Actualizacion del pending que sale de una FIFO hacia el Bus de datos
	forever begin
		@(negedge vif.clk);
			vif.pending[0][identify] = pending; 
			pop = vif.pop[0][identify];
		end
	endtask
	
	
	task Dout_uptate() // Visto desde la FIFO: actualiza el valor de salida de la fifo (o sea el valor de entrada del bus) y el valor de pending 
	forever begin
		@(posedge vif.clk);
			vif.Data_pop[0][identify] = fifo_queue[0]; // Indica que el dato de entrada al bus de datos va a estar almacenado en la posicion 
			if(pop ==1) begin
				fifo_queue.pop_front(); //Eliminando el primer elemento de la fifo.
			end 
			
			if (fifo_queue.size ==0)begin //Se revisa si el tamaño de la queue (fifo) es 0 implica que no hay dato pendiente que enviar al bus de datos
				pending = 0;
			end
	endtask
	
	function void Din_update(bit [pckg_sz-1:0] dato); 
			fifo_queue.push_back(dato);    //Ingresa el dato en la fifo.
			pending = 1;
	endfunction
endclass



class driver_hijo #(parameter pckg_sz = 32, parameter drvrs=5);
		fifo_driver #(.pckg_sz(pckg_sz), .drvrs(drvrs)) fifo_d;
		
		agent_driver_mailbox  adm; // Se define el manejador adm que apunta al objeto agent_driver_mailbox 
		driver_checker_mailbox dcm; // Manejador que apunta al driver_checker_mailbox
		
		int HOLD;
		int ident;
		
		function new (int identify);
			this.ident = identify;
			this.fifo_d = new(id);
		endfunction 
		
		
		task inicia ();
		
		$display ("Driver # [%g] se inicializa en tiempo [%g]",ident,$time);
			fork
			fifo_d.pen_update();
			fifo.Dout_uptate();
			join_none
		
		@(posedge fifo.vif.clk);
			fifo.vif.reset[ident]=1;
		@(posedge fifo.vif.clk);
			forever begin 
				trans_bus #(.pckg_sz(pckg_sz),.drvrs(drvrs)) transacciones;
				fifo.vif.rst[ident]=0;
				$display("Driver # [%g] esperando transaccion",ident,$time);
				HOLD = 0;
				@(posedge fifo.vif.clk);
					adm.get(transacciones); //Conecta mailbox al handler que apunta al bus de transacciones
					$display("Driver # [%g] recibe transaccion en tiempo [%g]",ident,$time);
				
				while(HOLD<transacciones.retardo) begin
					@(posedge fifo.vif.clk);
						HOLD=HOLD +1;
				end
				
				if(transacciones.Tx ==ident)begin
					transacciones.tiempo = $time;
					@(posedge fifo.vif.clk);
						fifo_d.Din_update(transacciones.dato);//Ingresa el dato dado por la variable DATO en el Trans_bus y lo agrega a la variable de Din_update de la clase fifo_d
						$display("Driver[%g]: transaccion completada en tiempo [%g]",ident,$time);
						dcm.put(transacciones); //Envia la transaccion al checker desde el bus de transacciones
				end
			end
			
		endtask
		
endclass


class driver_padre #(parameter pckg_sz =32, parameter drvrs =4);
	driver_hijo #(.pckg_sz(pckg_sz), .drvrs(drvrs)) driver_h; // handler que apunta a la clase driver_hijo
	
	function new();
		for(int i=0; i< drvrs; i++)begin
			driver_h[i]=new(i); // Genera varias instancias de la clase driver_hijo
		end
	endfunction
	
	
	task inicia();
	
		for (int i=0; i< drvrs; i++)begin
			fork
				automatic int j=i;
					begin
						driver_h[j].run(); // Hace un for para que los procesos hijos se ejecuten de forma simultánea.
					end
			join_none
		end
		
	endtask
	
endclass
