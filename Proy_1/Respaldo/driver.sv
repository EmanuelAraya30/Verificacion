// Driver
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: Este objeto es responsable de majear las señales de entradas del DUT. 

class fifo_driver #(parameter pckg_sz = 32, parameter bits = 1, parameter drvrs=5);
  bit push; 
  bit pop;
  bit pndng;
  bit [pckg_sz-1:0] Data_pop; // Se definen la variable que almacena el dato que se saca de la fifo
  bit [pckg_sz-1:0] fifo_queue [$]; //Se crea una fifo
  int ident;
  virtual bus_if #(.pckg_sz(pckg_sz), .drvrs(drvrs)) vif; //Se instancia la interfaz virtual  
  
  function new(int identify); //Se pasa como parametro la variable identify para que este sea el valor a que se iguala ident 
    this.push = 0;
    this.pop = 0;
    this.pndng = 0;
    this.Data_pop = 0;
	  this.fifo_queue = {};
    this.ident = identify; //La funcion de ident es identificar las diferentes instancias de Driver Padre y Driver Hijo
  endfunction 
  
  
  task pen_update(); //Actualizacion del pending que sale de una FIFO hacia el Bus de datos
    forever begin
      @(negedge vif.clk); // Para cada flanco de reloj negativo de la interfaz virtual 
      vif.pndng[0][ident] = pndng; // Asigna un valor de pending a cada una de las instancias de las FIFO IN que comunican los terminales con el DUT
      pop = vif.pop[0][ident]; // Asigna el valor de pop a cada una de las instancias de las FIFO IN. 
    end
  endtask
  
  task Dout_uptate(); // Visto desde la FIFO: actualiza el valor de entrada de la fifo (o sea el valor de salida de los terminales).
    forever begin
      @(posedge vif.clk);
      vif.Data_pop[0][ident] = fifo_queue[0]; // Se asigna el dato que se va a eliminar de uno de los terminales y se envia a la posicion 0 de la fifo_queue
      if(pop ==1) begin
        fifo_queue.pop_front(); //Eliminando el primer elemento de la fifo.
      end 
      if (fifo_queue.size ==0)begin //Se revisa si el tamaño de la queue (fifo) es 0 implica que no hay dato pendiente que enviar al bus de datos
        pndng = 0;
      end
    end
  endtask
  
  
  function void Din_update(bit [pckg_sz-1:0] dato); //Recibe como parametro dato que es la transaccion que se quiere enviar al DUT
    fifo_queue.push_back(dato);    //Ingresa el dato en la fifo.
    pndng = 1;
  endfunction
endclass



class driver_hijo #(parameter pckg_sz = 32, parameter bits=1, parameter drvrs=5);
  fifo_driver #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) fifo_d;
  adm agent_driver_mailbox; // Se define el mailbox que conecta al agente con el driver.
  dcm driver_checker_mailbox; // Se define manejador que conecta al driver con el checker.
  int HOLD; // Esta variable se utilizará como contador para generar los retardos entre transacciones.
  int ident;

  function new (int identify);
    this.ident = identify;
    this.fifo_d = new(identify); //Se inicializa la clase fifo_d con el constructor y se le pasa el parámetro identify
  endfunction 
  
  task inicia();
    $display ("Driver # [%g] se inicializa en tiempo [%g]",ident,$time);
    fork
      fifo_d.pen_update(); //Ejecuta procesos actualizacion del pending y los datos de entrada en la fifo
      fifo_d.Dout_uptate();
    join_none
    
    
    @(posedge fifo_d.vif.clk);
    fifo_d.vif.rst[ident]=1;  //Asigna el valor de rst de cada instancia de la interfaz virtual a 1
    @(posedge fifo_d.vif.clk);
    forever begin 
      trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transacciones;
      fifo_d.vif.rst[ident]=0;  //Asigna el valor de rst de cada instancia de la interfaz virtual a 1
      
      $display("Driver # [%g] esperando transaccion en tiempo [%g]",ident,$time);
      HOLD = 0;
      @(posedge fifo_d.vif.clk);
      agent_driver_mailbox.get(transacciones); //Conecta mailbox al handler que apunta al bus de transacciones
      $display("Driver # [%g] recibe transaccion en tiempo [%g]",ident,$time);
      while(HOLD<transacciones.retardo) begin
        @(posedge fifo_d.vif.clk);
        HOLD=HOLD +1; //Incrementar el contador HOLD para que no se envien  las transacciones hasta que se haya cumplido el tiempo de retardo
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
  driver_hijo #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) driver_h [drvrs]; //Instancia de driver_hijo para generar los 5 procesos hijos
  function new();
    for(int i=0; i< drvrs; i++)begin
      driver_h[i]=new(i); //Genera instancias de los procesos hijos segun la cantidad de drivers
    end
  endfunction
  
  task inicia();
    for (int i=0; i< drvrs; i++)begin
      fork
        automatic int j=i;
        begin
          driver_h[j].inicia(); // Se ejecuta un ciclo for y un proceso fork join none para que cada hijo generado se ejecute en paralelo
        end
      join_none
    end	
  endtask
	
endclass