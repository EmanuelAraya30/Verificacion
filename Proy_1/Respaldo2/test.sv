class test #(parameter pckg_sz = 32, parameter drvrs =5, parameter bits=1);
  virtual bus_if #(.pckg_sz(pckg_sz)) vif [drvrs];
  
  
  //Definicion de mailboxes
  tam test_agent_mailbox;
  rm reporte_mailbox;
  
  parameter num_trans_ag = 10;
  parameter max_retardo_ag = 20;
  
  
  instruct tipo;
  reporte  reporte_inst;
  
  ambiente #(.pckg_sz(pckg_sz), .drvrs(drvrs), .bits(bits)) ambiente_inst;
  
  function new();
  test_agent_mailbox = new();
  reporte_mailbox =new();
    ambiente_inst = new();
    ambiente_inst.agent_inst.num_trans_ag = num_trans_ag;
    ambiente_inst.agent_inst.max_retardo_ag= max_retardo_ag;
    ambiente_inst.agent_inst.test_agent_mailbox=test_agent_mailbox;
    ambiente_inst.scoreboard_inst.reporte_mailbox =reporte_mailbox;
  endfunction
  
  
  task inicia();
    $display("Se inicializa Test en tiempo [%g]",$time);
    fork
      ambiente_inst.inicia();
    join_none
    
    
    tipo = transaccion_aleat; //cantidad de transacciones
    test_agent_mailbox.put(tipo);
    $display(" Transacciones aleatorias efectuadas en tiempo [%g], con numero de transacciones=%g", $time,num_trans_ag);
    
    tipo = broadcast; //Cantidad de dispositivos
    test_agent_mailbox.put(tipo);
    $display(" Transacciones de tipo broadcast en tiempo [%g] con numero de transacciones=%g", $time,num_trans_ag);
    
    tipo = trans_todos; // Prueba de reset
    test_agent_mailbox.put(tipo);
    $display(" Envio de transacciones a todos los dispositivos =[%g] con numero de transacciones=%g", $time,num_trans_ag);
    
    tipo = retardo_min; // Retardo aleatorio 
    test_agent_mailbox.put(tipo);
    $display(" Transaccion con retardo aleatorio en tiempo [%g] con numero de transacciones=%g", $time,num_trans_ag);
    
    tipo = trans_determinada; // Direcciones de ID inválidas 
    test_agent_mailbox.put(tipo);
    $display("Transacciones con direcciones de envio invalidas en tiempo [%g] con numero de transacciones=%g", $time,num_trans_ag);
    
    
    tipo = trans_determinada;
    ambiente_inst.agent_inst.retardo_ag = 7;
    ambiente_inst.agent_inst.info_ag = 255;
    ambiente_inst.agent_inst.Tx_ag = drvrs-1;
    ambiente_inst.agent_inst.Rx_ag = 2;
    ambiente_inst.test_agent_mailbox.put(tipo);
	
	$display("[%g] Transacciones especificas creadas con n_transacciones=%g",$time,num_trans_ag);
    #2000000;
	
	//Se encuentra el ancho de banda de transmision // Cambiar de acá para abajo
      	
    ambiente_inst.scoreboard_inst.inicio=1;
    ambiente_inst.scoreboard_inst.cont_inst_bw=0;
    ambiente_inst.scoreboard_inst.tiempo_init=0;
    ambiente_inst.scoreboard_inst.tiempo_fin=0;
        
    ambiente_inst.agent_inst.num_trans_ag=100;
    ambiente_inst.agent_inst.max_retardo_ag=1;
    tipo=transaccion_aleat;
    test_agent_mailbox.put(tipo);
    #2000000;
  
    reporte_inst=reporte_bw_max;
    reporte_mailbox.put(reporte_inst);
    #100;
    ambiente_inst.scoreboard_inst.inicio=1;
    ambiente_inst.scoreboard_inst.cont_inst_bw=0;
    ambiente_inst.scoreboard_inst.tiempo_init=0;
    ambiente_inst.scoreboard_inst.tiempo_fin=0;
	
	  ambiente_inst.agent_inst.num_trans_ag=100;    	
    tipo= trans_determinada;
    ambiente_inst.agent_inst.retardo_ag=1;
    ambiente_inst.agent_inst.info_ag=0;
    ambiente_inst.agent_inst.Rx_ag=0;
    ambiente_inst.agent_inst.Tx_ag=drvrs-1;
    test_agent_mailbox.put(tipo);
    #2000000;
      
    reporte_inst=reporte_bw_min;
    reporte_mailbox.put(reporte_inst);
    reporte_inst=reporte_prom;
    reporte_mailbox.put(reporte_inst);
    reporte_inst=reporte_transac;
    reporte_mailbox.put(reporte_inst);
	#100;
      	
    $display("[%g]numero de transacciones realizadas =%g", $time, ambiente_inst.scoreboard_inst.cont_intruct);
    $display("Run seed= %d", $get_initial_random_seed());
	$display("Se alcanza el tiempo limite de la prueba");
	$finish;
	
    
  endtask
endclass