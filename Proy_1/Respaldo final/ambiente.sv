class ambiente #(parameter pckg_sz=32, parameter drvrs=5, parameter bits=1);
  
  //Componentes del ambiente
  agent #(.pckg_sz(pckg_sz), .drvrs(drvrs)) agent_inst;
  driver_padre #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) driver_padre_inst;
  monitor_padre #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) monitor_padre_inst;
  checker #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) checker_inst;
  score_board #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) scoreboard_inst;
  
  virtual bus_if #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) vif;

  // Declaracion de los Mailboxes
  
  tam test_agent_mailbox; 
  adm agent_driver_mailbox[drvrs];
  dcm driver_checker_mailbox;
  mcm monitor_checker_mailbox;
  csm checker_scoreboard_mailbox;
  rm reporte_mailbox;
  
  
  //Se inicializan los mailbox pertenecientes a los drivers
  function new();
    for(int j=0; j< drvrs; j++)begin
      agent_driver_mailbox[j]=new();
    end
    
  checker_scoreboard_mailbox=new();
  test_agent_mailbox=new();
	driver_checker_mailbox=new();
	monitor_checker_mailbox=new();
 
      
	//intancias de componentes del ambiente
	agent_inst=new();
	driver_padre_inst=new();
    monitor_padre_inst=new();
    checker_inst=new();
    scoreboard_inst=new();
	
	//Se efectua la conexión de los mailbox
	for(int j=0; j<drvrs; j++)begin
        monitor_padre_inst.FiFo_son[j].monitor_checker_mailbox  = monitor_checker_mailbox;
        driver_padre_inst.driver_h[j].agent_driver_mailbox  = agent_driver_mailbox[j];
        driver_padre_inst.driver_h[j].driver_checker_mailbox  = driver_checker_mailbox;
        agent_inst.agent_driver_mailbox[j]                  = agent_driver_mailbox[j];
      end
	
	//Conexion de las interfaces y mailboxes
    
    scoreboard_inst.reporte_mailbox          =reporte_mailbox;
    checker_inst.driver_checker_mailbox           =driver_checker_mailbox;
    checker_inst.monitor_checker_mailbox           =monitor_checker_mailbox;
    checker_inst.checker_scoreboard_mailbox           =checker_scoreboard_mailbox;
    scoreboard_inst.checker_scoreboard_mailbox        =checker_scoreboard_mailbox;
	  agent_inst.test_agent_mailbox             =test_agent_mailbox;
  endfunction
  
  virtual task inicia();
    $display("[%g] El ambiente fue inicializado", $time);
	for(int j=0; j<drvrs; j++)begin
          monitor_padre_inst.FiFo_son[j].FiFo_out.vif=vif;
          driver_padre_inst.driver_h[j].fifo_d.vif=vif;
	end
	
	
    fork
	  agent_inst.inicia();
      driver_padre_inst.inicia();
	  monitor_padre_inst.inicia();
	  checker_inst.save();
	  checker_inst.match();
	  scoreboard_inst.run();
	  
    join_none
  endtask
endclass