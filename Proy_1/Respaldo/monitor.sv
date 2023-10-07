

//fifo simulada
class fifomonitor #(parameter width=32, parameter bits=1, parameter n_term=5);
	virtual switch_if #(.width(width), .bits(bits), .n_term(n_term)) vif;
  	bit pop;
	bit push;
	bit pndng;
    	bit [width-1:0] Dout;
    	bit [width-1:0] D_push;
	bit [width-1:0] fifosimul [$];
    	int ident;
  
  	function new(int id);
	   this.pop=0;
	   this.push=0;
	   this.pndng=0;
	   this.Dout=0;
	   this.fifosimul= {};
           this.ident=id;
	endfunction
  
  
  	task pushf();//funcion que actualiza el push que proviene del DUT
		forever begin
		@(posedge vif.clk);
          	push=vif.push[0][ident];
		end
	endtask
    	task update(); //Actualiza el dato que proviene del DUT en la entrada de la fifo
		forever begin
		@(posedge vif.clk);
       		   D_push=vif.D_push[0][ident];
         	   if(push==1)begin
            	   fifosimul.push_back(D_push);
                   pndng=1;
		  end
		end
	endtask
  
  	function void popf();//Saca el dato recibido de la fifo 
		Dout=fifosimul.pop_front();
     		 if(fifosimul.size()==0)begin
       		  pndng=0;
     		 end
	endfunction
  
endclass

//Monitor hijo
class monitor_child #(parameter width=32, parameter bits=1, parameter n_term=5);
  	
  fifomonitor  #(.width(width), .bits(bits), .n_term(n_term)) fifo;
  trans_monitor #(.width(width)) transaccion;
  comando_mnt_chk_mbx mnt_chk_mbx;
  
  int ident;
  
  function new(int id);
    this.ident=id;
    this.fifo=new(id);
  endfunction
    
    
    task run();
      $display("[%g] Monitor # [%g] ha inicializado", $time, ident);
      fork //se corren las funciones de fifo
        fifo.pushf();
        fifo.update();
      join_none
      	
      forever begin
      	transaccion=new;
        @(posedge fifo.vif.clk);
        if(fifo.pndng==1)begin//Espera a que se obtenga un dato
          
          fifo.popf();
          transaccion.tiempo=$time;
          transaccion.terminal_recibo=ident;
          @(posedge fifo.vif.clk);
          transaccion.dato=fifo.Dout;
          mnt_chk_mbx.put(transaccion);//Se envia la transaccion recibida al checker
          transaccion.print("Monitor: Transaccion recibida");
        end
        @(posedge fifo.vif.clk);
      end
    endtask
  
endclass

//Monitor padre
class monitor_master #(parameter width=32,parameter n_term=5, parameter bits=1 );
      monitor_child #(.width(width), .bits(bits), .n_term(n_term)) monitorc [n_term];


  function new();
    for(int i=0; i<n_term; i++)begin
    	//se corren cada unos de los hijos
        monitorc[i]=new(i);
      end
  endfunction
  	
  
  task run();
     
    for(int i=0; i < n_term; i++ )  begin
      fork
        automatic int j = i;
        begin
          //Se ejecutan los hijos al mismo tiempo
          monitorc[j].run();
          
        end
      join_none
    end
  endtask
endclass