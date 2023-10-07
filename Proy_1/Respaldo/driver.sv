
//fifo simulada
class fifoemul_driver #(parameter width=32, parameter bits=1, parameter n_term=5);
	bit pop;
	bit push;
	bit pndng;
	bit [width-1:0] D_pop;
	bit [width-1:0] fifosimul [$];
    	int ident;
  	virtual switch_if #(.width(width), .bits(bits), .n_term(n_term)) vif;

  	function new(int id);
	   this.pop=0;
	   this.push=0;
	   this.pndng=0;
	   this.D_pop=0;
	   this.fifosimul= {};
       	   this.ident=id;
	endfunction

	task popf(); //actualiza pending hacia el DUT y 	
	forever begin //el pop proveniente del DUT cada ciclo de reloj
          @(negedge vif.clk);
          vif.pndng[0][ident]=pndng;
          pop=vif.pop[0][ident];
		end
	endtask

	task update();//actualiza el valor de salida de la fifo y el valor de pending 
	forever begin
          @(posedge vif.clk);
          vif.D_pop[0][ident]=fifosimul[0];
		if(pop==1)begin
		    fifosimul.pop_front();
       		 end
		  if(fifosimul.size()==0)begin
			pndng=0;
		  end
		end
	endtask

  	function void pushf(bit [width-1:0] dato); //funcion para ingresar el dato en la fifo
		fifosimul.push_back(dato);
    		pndng=1;
	endfunction

endclass 

//Driver hijo
class driver_child #(parameter width=32, parameter bits=1, parameter n_term=5);
	fifoemul_driver #(.width(width), .bits(bits), .n_term(n_term)) fifo; //fifo simulada
	comando_agnt_drv_mbx agnt_drv_mbx; //mailbox de agente a driver
	comando_drv_chk_mbx drv_chk_mbx; //mailbox de driver a checker
	int espera;
	int ident;
  	
	function new(int id);
	  this.ident=id;
          this.fifo=new(id);
	endfunction

  	task run();
    	$display("[%g] Driver # [%g] ha inicializado", $time,ident);
		fork //Se corren las funciones de fifo
		fifo.popf(); 
		fifo.update();
		join_none
		
        @(posedge fifo.vif.clk);
        fifo.vif.rst[ident]=1;
        @(posedge fifo.vif.clk);
		forever begin
		trans_bus #(.width(width), .n_term(n_term)) transaccion; 
            	fifo.vif.rst[ident]=0;
          	$display("[%g] Driver: [%g] espera transaccion",$time,ident);
		espera=0;
          	@(posedge fifo.vif.clk);
		agnt_drv_mbx.get(transaccion);//Espera una transaccion del agente
          	$display("[%g] Driver[%g]: trans_rcb", $time, ident);
			
		while(espera< transaccion.retardo)begin//Espera para cumplir el retardo
              	@(posedge fifo.vif.clk);
			espera=espera+1;
		end
		if(transaccion.term_envio==ident)begin
		transaccion.tiempo=$time;
              	@(posedge fifo.vif.clk);
		fifo.pushf(transaccion.dato);//Ingresa el dato en la fifo
              	$display("[%g] Driver[%g]: trans_comp", $time, ident);
		drv_chk_mbx.put(transaccion); //Envia la transaccion al checker
		end
		
		end
	endtask
endclass

class driver_master #(parameter width=32, parameter n_term=4, parameter bits=1);
    driver_child #(.width(width), .bits(bits), .n_term(n_term)) driverc [n_term];
	
 
  function new();
    for(int i=0; i<n_term; i++)begin
        driverc[i]=new(i);
      end
  endfunction
  	
  
  task run();
     
    for(int i=0; i < n_term; i++ )  begin
      fork

       automatic int j = i;
        begin
          //Se generan los hijos en paralelo
          driverc[j].run();
          
        end
      join_none
    end
        
  endtask	
endclass
