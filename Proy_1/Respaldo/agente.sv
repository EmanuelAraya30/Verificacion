// Agente
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: encargado de convertir instrucciones complejas.
// Envía instrucciones al scoreboard



/*class number_trans_aleat #(parameter bits=1,  parameter drvrs=4, parameter pckg_sz = 32);
  rand int aleat;
  constraint const_aleat {aleat <10; aleat>0;}
endclass */


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
 /// Agente: responsable de convertir instrucciones complejas en simples para pasarlas al driver //////////////
 //////////////////////////////////////////////////////////////////////////////////////////////////////////////


class agent #(parameter bits=1,  parameter drvrs=4, parameter pckg_sz = 32);
  
  adm agent_driver_mailbox[drvrs]; //Se define el mailbox que conecta al agente y las instancias del driver
  tam test_agent_mailbox;  //Se define el mailbox que conecta el test con el agente
  
  instruct tipo; // Se define typedef instruct para indicar los diferentes tipos de instrucciones 
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transacciones; //Se define el handler transacciones para pasar las instrucciones por medio de mailboxes
  //transacciones apunta a la clase trans_bus
  int num_trans_ag; //numero de 
  int max_retardo_ag;  // Almacenara el valor de retardo maximo
  int retardo_ag;
  int max_terminales_ag;
  bit [pckg_sz-13:0] info_ag;
  bit [3:0] Tx_ag;
  bit [7:0] Rx_ag;

  //number_trans_aleat  aleatorio = new();

  
  
  
  task inicia();
    $display("El agente se inicializa en el tiempo [%g]", $time);
    aleatorio.randomize();
    
    
    forever begin
      #1
      if (test_agent_mailbox.num()>0);begin
        $display("El agente # %g  recibe una instruccion",$time );
        test_agent_mailbox.get(tipo);
        case(tipo)
          trans_aleat:begin //Etiqueta que define el tipo de instruccion ejecutada
            for(int i=0; i<num_trans_ag; i++)begin
              transacciones = new(); //Inicializa la clase Trans_Bus
              transacciones.max_retardo= max_retardo_ag; //Accede a la propiedad 'max_retardo' de Trans_Bus y le asigna un valor de retardo
              transacciones.tipo=tipo;  //Asigna a la propiedad 'tipo' de Trans_Bus el tipo de instruccion segun el typedef tipo
              transacciones.randomize(); // Accede a las variables tipo rand y randc y las aleatoriza
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion}; //Efectua una concatenacion de los datos de ID, terminal de envio e informacion pura
              agent_driver_mailbox[transacciones.dato_env].put(transacciones); //transacciones.dato_env indica la terminal (de 0 a 15)  donde se envian las transacciones del agente al driver
            end		
		  end
          
          broadcast:begin //En cada terminal se hacen envios a todos
            for(int j=0; j<num_trans_ag;j++)begin  
              transacciones = new(); 
              transacciones.max_retardo= max_retardo_ag;  
              transacciones.tipo=tipo; 
              transacciones.randomize(); 
              transacciones.dato_rec={8{1'b1}}; // especifica que se hace broadcast a todas las terminales
              transacciones.dato_rec = 0;
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_env].put(transacciones); // transacciones.dato_env indica la terminal (de 0 a 15)  donde se envian las transacciones del agente al driver
            end
          end
          
          
          
          trans_each:begin //Transacciones con retardo aleatorio
            for(int j=0; j<drvrs; j++)begin // j se mantiene constante primero e i es variable
              for(int i=0; i<drvrs; i++)begin
                transacciones = new();
              	transacciones.max_retardo=max_retardo_ag;
              	transacciones.tipo=tipo;
              	transacciones.randomize();
              	transacciones.dato_rec = i; // Las terminales que reciben info cambiaran de 0 a 15
              	transacciones.dato_env = j; // Las terminales de enivan info cambiaran de 0 a 15
              	transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              	transacciones.print("Agente: transaccion:");
              	agent_driver_mailbox[transacciones.dato_env].put(transacciones); // transacciones.dato_env indica la terminal (de 0 a 15)  donde se envian las transacciones del agente al driver
              end
            end
          end
          
          trans_retarmin:begin //Transacciones especificas
            for(int i=0; i<num_trans_ag; i++)begin
              transacciones = new();
              transacciones.retardo=retardo_ag;
              transacciones.tipo=tipo;
              transacciones.dato=retardo_ag;
              transacciones.retardo =1; //Asigna el atributo retardo de Trans_bus el valor de 1
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_env].try_put(transacciones);
            end
          end
          
          
          trans_spec:begin //Transacciones especificas
            for(int i=0; i<num_trans_ag; i++)begin
              transacciones = new();
              transacciones.retardo=retardo_ag;
              transacciones.tipo=tipo;
              transacciones.dato= info_ag; //Se asigna informacion especifica al atributo dato de Trans_bus
              transacciones.dato_rec= Rx_ag; //Se asigna al atributo dato_recibido de Trans Bus una direccion especifica
              transacciones.dato_env= Tx_ag; //Se asigna al atributo dato_env de Trans Bus una direccion especifica
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_env].try_put(transacciones);
            end
          end
          /*
          num_trans_aleat:begin
            for(int i=0; i<aleatorio.aleat; i++)begin
              transacciones = new(); //Inicializa la clase Trans_Bus
              transacciones.max_retardo= max_retardo_ag; //Accede a la propiedad 'max_retardo' de Trans_Bus y le asigna un valor de retardo
              transacciones.tipo=tipo;  //Asigna a la propiedad 'tipo' de Trans_Bus el tipo de instruccion segun el typedef tipo
              transacciones.randomize(); // Accede a las variables tipo rand y randc y las aleatoriza
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion}; //Efectua una concatenacion de los datos de ID, terminal de envio e informacion pura
              agent_driver_mailbox[transacciones.dato_env].put(transacciones);
            end
          end */
        endcase
      end
    end
  endtask
endclass