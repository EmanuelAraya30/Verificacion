class fifo_driver #(parameter pckg_sz = 32, parameter bits = 1, parameter drvrs=5);
  bit push;
  bit pop;
  bit pndng;
  bit [pckg_sz-1:0] Data_pop;
  bit [pckg_sz-1:0] fifo_queue [$];
  int ident;
  virtual bus_if #(.pckg_sz(pckg_sz), .drvrs(drvrs)) vif;
  
  function new(int identify);
    this.push = 0;
    this.pop = 0;
    this.pndng = 0;
    this.Data_pop = 0;
	this.fifo_queue = {};
    this.ident = identify;
    
  endfunction 
  
  
  task pen_update(); //Actualizacion del pending que sale de una FIFO hacia el Bus de datos
    forever begin
      @(negedge vif.clk);
      vif.pndng[0][ident] = pndng; 
      pop = vif.pop[0][ident];
    end
  endtask
  
  task Dout_uptate(); // Visto desde la FIFO: actualiza el valor de salida de la fifo (o sea el valor de entrada del bus) y el valor de pending 
    forever begin
      @(posedge vif.clk);
      vif.Data_pop[0][ident] = fifo_queue[0]; // Indica que el dato de entrada al bus de datos va a estar almacenado en la posicion 
      if(pop ==1) begin
        fifo_queue.pop_front(); //Eliminando el primer elemento de la fifo.
      end 
      if (fifo_queue.size ==0)begin //Se revisa si el tamaño de la queue (fifo) es 0 implica que no hay dato pendiente que enviar al bus de datos
        pndng = 0;
      end
    end
  endtask
  
  
  function void Din_update(bit [pckg_sz-1:0] dato); 
    fifo_queue.push_back(dato);    //Ingresa el dato en la fifo.
    pndng = 1;
  endfunction
endclass



class driver_hijo #(parameter pckg_sz = 32, parameter bits=1, parameter drvrs=5);
  fifo_driver #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) fifo_d;
  adm agent_driver_mailbox; // Se define el manejador adm que apunta al objeto agent_driver_mailbox 
  dcm driver_checker_mailbox; // Manejador que apunta al driver_checker_mailbox
  int HOLD;
  int ident;

  function new (int identify);
    this.ident = identify;
    this.fifo_d = new(identify);
  endfunction 
  
  task inicia();
    $display ("Driver # [%g] se inicializa en tiempo [%g]",ident,$time);
    fork
      fifo_d.pen_update();
      fifo_d.Dout_uptate();
    join_none
    
    
    @(posedge fifo_d.vif.clk);
    fifo_d.vif.rst[ident]=1;
    @(posedge fifo_d.vif.clk);
    forever begin 
      trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transacciones;
      fifo_d.vif.rst[ident]=0;
      
      $display("Driver # [%g] esperando transaccion en tiempo [%g]",ident,$time);
      HOLD = 0;
      @(posedge fifo_d.vif.clk);
      agent_driver_mailbox.get(transacciones); //Conecta mailbox al handler que apunta al bus de transacciones
      $display("Driver # [%g] recibe transaccion en tiempo [%g]",ident,$time);
      while(HOLD<transacciones.retardo) begin
        @(posedge fifo_d.vif.clk);
        HOLD=HOLD +1;
      end
      
      if(transacciones.dato_env ==ident)begin
        transacciones.tiempo = $time;
        @(posedge fifo_d.vif.clk);
        fifo_d.Din_update(transacciones.dato);//Ingresa el dato dado por la variable DATO en el Trans_bus y lo agrega a la variable de Din_update de la clase fifo_d
        //$display(ident);
        $display("Driver[%g]: transaccion completada en tiempo [%g]",ident,$time);
        driver_checker_mailbox.put(transacciones); //Envia la transaccion al checker desde el bus de transacciones
      end
    end
  endtask
endclass


class driver_padre #(parameter pckg_sz =32, parameter drvrs =5, parameter bits=1);
  driver_hijo #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) driver_h [drvrs]; 
  // handler que apunta a la clase driver_hijo
  function new();
    for(int i=0; i< drvrs; i++)begin
      driver_h[i]=new(i);
    end
  endfunction
  
  task inicia();
    for (int i=0; i< drvrs; i++)begin
      fork
        automatic int j=i;
        begin
          driver_h[j].inicia(); // Hace un for para que los procesos hijos se ejecuten de forma simultánea.
        end
      join_none
    end	
  endtask
	
endclass