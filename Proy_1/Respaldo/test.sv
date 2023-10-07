// Test
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: Genera las limitaciones en los escenarios de prueba.
// Identifica las funciones que se ejecutarán y las limitaciones 
// en la aleatoriedad.

class test #(parameter pckg_sz = 32, parameter drvrs =5, parameter bits=1);
  virtual bus_if #(.pckg_sz(pckg_sz)) vif [drvrs];
  
  
  //Definicion de mailboxes
  tam test_agent_mailbox;
  rm reporte_mailbox;
  
  parameter num_trans_ag = 50;
  parameter max_retardo_ag = 30;
  
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
    
    
    tipo = trans_aleat; // Prueba de transacciones aleatorias
    test_agent_mailbox.put(tipo);
    $display("Se efectua transaccion aleatoria en tiempo %g con %g transacciones", $time,num_trans_ag);
    
    tipo = broadcast; // Prueba de broadcast
    test_agent_mailbox.put(tipo);
    $display("Se efectua transaccion de broadcast en tiempo %g con %g transacciones", $time,num_trans_ag);
    
    tipo = trans_each; // Prueba de reset
    test_agent_mailbox.put(tipo);
    $display("Se efectuan transacciones en todas las terminales en tiempo %g con %g transacciones", $time,num_trans_ag);
    
    tipo = trans_retarmin; // Retardo aleatorio 
    test_agent_mailbox.put(tipo);
    $display("Se efectuan transacciones de retardo aleatorio en tiempo %g con %g transacciones", $time,num_trans_ag);
    
    tipo = trans_spec; // Direcciones de ID inválidas 
    test_agent_mailbox.put(tipo);
    $display("Se efectuan transacciones con direcciones de ID en tiempo %g con %g transacciones", $time,num_trans_ag);
    
    //tipo = num_trans_aleat; // Numero aleatorio de transacciones 
    //test_agent_mailbox.put(tipo);
    //$display("Se efectuan numero aleatorio de transacciones en tiempo %g con %g transacciones", $time,num_trans_ag);

    
    tipo = trans_spec;
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
    tipo=trans_aleat;
    test_agent_mailbox.put(tipo);
    #2000000;
  
    reporte_inst=rpt_bw_max;
    reporte_mailbox.put(reporte_inst);
    #100;
    ambiente_inst.scoreboard_inst.inicio=1;
    ambiente_inst.scoreboard_inst.cont_inst_bw=0;
    ambiente_inst.scoreboard_inst.tiempo_init=0;
    ambiente_inst.scoreboard_inst.tiempo_fin=0;
	
	  ambiente_inst.agent_inst.num_trans_ag=100;    	
    tipo= trans_spec;
    ambiente_inst.agent_inst.retardo_ag=1;
    ambiente_inst.agent_inst.info_ag=0;
    ambiente_inst.agent_inst.Rx_ag=0;
    ambiente_inst.agent_inst.Tx_ag=drvrs-1;
    test_agent_mailbox.put(tipo);
    #2000000;
      
    reporte_inst=rpt_bw_min;
    reporte_mailbox.put(reporte_inst);
    reporte_inst=rpt_prom;
    reporte_mailbox.put(reporte_inst);
    reporte_inst=rpt_transac;
    reporte_mailbox.put(reporte_inst);
	#100;
      	
    $display("[%g]numero de transacciones realizadas =%g", $time, ambiente_inst.scoreboard_inst.cont_intruct);
    $display("Run seed= %d", $get_initial_random_seed());
	$display("Se alcanza el tiempo limite de la prueba");
	$finish;
	
    
  endtask
endclass
