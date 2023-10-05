class ambiente #(parameter pckg_sz=32, parameter drvrs=5, parameter bits=1);
  
  //Componentes del ambiente
  agent #(.pckg_sz(pckg_sz), .drvrs(drvrs)) agent_inst;
  driver_padre #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) driver_padre_inst;
  monitor_padre #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) monitor_padre_inst;
  checker #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) checker_inst;
  scoreboard #(.pckg_sz(pckg_sz),.drvrs(drvrs), .bits(bits)) scoreboard_inst;
  
  virtual bus_if #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) vif;

  // Declaracion de los Mailboxes
  
  test_agent_mailbox tam; 
  agent_driver_mailbox adm [drvrs];
  driver_checker_mailbox dcm;
  monitor_checker_mailbox mcm;
  checker_scoreboard_mailbox csm;
  reporte_mailbox rm;
  
  
  //Se inicializan los mailbox pertenecientes a los drivers
  function new();
    for(int j=0; j< drvrs; j++)begin
      adm[j]=new();
    end
    
    csm=new();
	tam=new();
	dcm=new();
	mcm=new();
 
      
	//intancias de componentes del ambiente
	agent_inst=new();
	driver_padre_inst=new();
    monitor_padre_inst=new();
    checker_inst=new();
    scoreboard_inst=new();
	
	//Se efectua la conexión de los mailbox
	for(int j=0; j<drvrs; j++)begin
        monitor_inst.FiFo_son[j].mcm       = mcm;
        driver_padre_inst.driver_h[j].adm  = adm[j];
        driver_padre_inst.driver_h[j].dcm  = dcm;
        agent_inst.adm[j]                  = adm[j];
      end
	
	//Conexion de las interfaces y mailboxes
    
    scoreboard_inst.rm          =rm;
    checker_inst.dcm           =dcm;
    checker_inst.mcm           =mcm;
    checker_inst.csm           =csm;
    scoreboard_inst.csm        =csm;
	agent_inst.tam             =tam;
  endfunction
  
  virtual task inicia();
    $display("[%g] El ambiente fue inicializado", $time);
	for(int j=0; j<drvrs; j++)begin
          monitor_inst.FiFo_son[j].FiFo_out.vif=vif;
          driver_inst.driver_h[j].fifo_d.vif=vif;
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