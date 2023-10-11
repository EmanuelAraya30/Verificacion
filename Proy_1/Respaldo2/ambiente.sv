// Ambiente
// Instituto Tecnologico de Costa Rica (www.tec.ac.cr)
// Escuela de Ingeniería Electrónica
// Prof: Ing. Ronny Garcia Ramirez. (rgarcia@tec.ac.cr)
// Estudiantes: -Enmanuel Araya Esquivel. (emanuelarayaesq@gmail.com)
//              -Randall Vargas Chaves. (randallv07@gmail.com)
// Curso: EL-5511 Verificación funcional de circuitos integrados
// Este Script esta estructurado en System Verilog
// Propósito General: Diseño de pruebas en capas para un BUS de datos
// Modulo: infraestructura necesarias para crear, ejecutar y analizar pruebas

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Ambiente: este módulo es el encargado de conectar todos los elementos del ambiente para que puedan ser usados por el test //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class ambiente #(parameter pckg_sz=32, parameter drvrs=5, parameter bits=1, parameter broadcast = {8{1'b1}});
  
  // Declaración de los componentes del ambiente
  agent #(.pckg_sz(pckg_sz), .drvrs(drvrs)) agent_inst;
  driver_padre #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) driver_padre_inst;
  monitor_padre #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) monitor_padre_inst;
  checker #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) checker_inst;
  score_board #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) scoreboard_inst;
  
  // Declaración de la interface que conecta el DUT 
  virtual bus_if #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) vif;

  //declaración de los mailboxes  
  tam test_agent_mailbox; 
  adm agent_driver_mailbox[drvrs];
  dcm driver_checker_mailbox;
  mcm monitor_checker_mailbox;
  csm checker_scoreboard_mailbox;
  rm reporte_mailbox;
  
  
  //Se inicializan los mailbox pertenecientes a los drivers
  function new();
    // Instanciación de los mailboxes
    for(int j=0; j< drvrs; j++)begin
      agent_driver_mailbox[j]=new();
    end
    checker_scoreboard_mailbox=new();
    test_agent_mailbox=new();
    driver_checker_mailbox=new();
    monitor_checker_mailbox=new();
  
    // instanciación de los componentes del ambiente
    agent_inst=new();
    driver_padre_inst=new();
    monitor_padre_inst=new();
    checker_inst=new();
    scoreboard_inst=new();
	
    // conexion de las interfaces y mailboxes en el ambiente
    for(int j=0; j<drvrs; j++)begin
      monitor_padre_inst.FiFo_son[j].monitor_checker_mailbox = monitor_checker_mailbox;
      driver_padre_inst.driver_h[j].agent_driver_mailbox = agent_driver_mailbox[j];
      driver_padre_inst.driver_h[j].driver_checker_mailbox = driver_checker_mailbox;
      agent_inst.agent_driver_mailbox[j] = agent_driver_mailbox[j];
    end
    
	  // instanciación de los componentes del ambiente
    scoreboard_inst.reporte_mailbox = reporte_mailbox;
    checker_inst.driver_checker_mailbox = driver_checker_mailbox;
    checker_inst.monitor_checker_mailbox = monitor_checker_mailbox;
    checker_inst.checker_scoreboard_mailbox = checker_scoreboard_mailbox;
    scoreboard_inst.checker_scoreboard_mailbox = checker_scoreboard_mailbox;
	  agent_inst.test_agent_mailbox = test_agent_mailbox;
  endfunction

  //Inicializa el ambiente
  virtual task inicia();
    $display("[%g] El ambiente fue inicializado", $time);
	for(int j=0; j<drvrs; j++)begin //Se inicia la cantidad de hijos driver y monitor
    monitor_padre_inst.FiFo_son[j].FiFo_out.vif = vif;
    driver_padre_inst.driver_h[j].fifo_d.vif = vif;
	end
	
    //Crea un hilo para iniciar los modulos
    fork
      agent_inst.inicia();
      driver_padre_inst.inicia();
      monitor_padre_inst.inicia();
      checker_inst.guardar();
      checker_inst.comparar();
      scoreboard_inst.run();
    join_none
  endtask
endclass
