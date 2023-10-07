class agent #(parameter bits=1,  parameter drvrs=4, parameter pckg_sz = 32);
  
  adm agent_driver_mailbox[drvrs];
  tam test_agent_mailbox; 
  
  instruct tipo; // Genera los diferentes tipos de test (transacciones)
  trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs)) transacciones;
  
  int num_trans_ag; //numero de transacciones
  int max_retardo_ag; 
  int retardo_ag;
  int max_terminales_ag;
  bit [pckg_sz-13:0] info_ag;
  bit [3:0] Tx_ag;
  bit [7:0] Rx_ag;
  
  
  task inicia();
    $display("El agente se inicializa en el tiempo [%g]", $time);
    forever begin
      #1
      if (test_agent_mailbox.num()>0);begin
        $display("El agente # %g  recibe una instruccion",$time );
        test_agent_mailbox.get(tipo);
        case(tipo)
          transaccion_aleat:begin //secuencia aleatoria de transacciones
            for(int i=0; i<num_trans_ag; i++)begin
              transacciones = new();
              transacciones.max_retardo= max_retardo_ag;
              transacciones.tipo=tipo;
              transacciones.randomize();
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_env].put(transacciones);
            end		
		  end
          
          broadcast:begin //En cada terminal se hacen envios a todos
            for(int j=0; j<num_trans_ag;j++)begin // j se mantiene consntate primero e i es variable 
              transacciones = new();
              transacciones.max_retardo= max_retardo_ag;
              transacciones.tipo=tipo;
              transacciones.randomize();
              transacciones.dato_env={8{1'b1}};
              transacciones.dato_rec = 0;
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_rec].put(transacciones);
            end
          end
          
          
          
          trans_todos:begin //Transacciones con retardo aleatorio
            for(int j=0; j<drvrs; j++)begin
              for(int i=0; i<drvrs; i++)begin
                transacciones = new();
              	transacciones.max_retardo=max_retardo_ag;
              	transacciones.tipo=tipo;
              	transacciones.randomize();
              	transacciones.dato_rec = i;
              	transacciones.dato_env = j;
              	transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              	transacciones.print("Agente: transaccion:");
              	agent_driver_mailbox[transacciones.dato_rec].put(transacciones);
              end
            end
          end
          
          retardo_min:begin //Transacciones especificas
            for(int i=0; i<num_trans_ag; i++)begin
              transacciones = new();
              transacciones.retardo=retardo_ag;
              transacciones.tipo=tipo;
              transacciones.dato=retardo_ag;
              transacciones.retardo =1;
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_env].try_put(transacciones);
            end
          end
          
          
          trans_determinada:begin //Transacciones especificas
            for(int i=0; i<num_trans_ag; i++)begin
              transacciones = new();
              transacciones.retardo=retardo_ag;
              transacciones.tipo=tipo;
              transacciones.dato= info_ag;
              transacciones.dato_rec= Rx_ag;
              transacciones.dato_env= Tx_ag;
              transacciones.dato={transacciones.dato_rec, transacciones.dato_env, transacciones.informacion};
              agent_driver_mailbox[transacciones.dato_env].try_put(transacciones);
            end
          end
        endcase
      end
    end
  endtask
endclass