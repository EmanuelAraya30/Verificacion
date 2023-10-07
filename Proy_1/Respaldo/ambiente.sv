class ambiente #(parameter width=32, parameter n_term=5, parameter bits=1);
	virtual switch_if #(.width(width), .bits(bits), .n_term(n_term)) vif;

	//Componentes del ambiente
    agent #(.width(width), .n_term(n_term)) agent_inst;
    driver_master #(.width(width),.n_term(n_term), .bits(bits)) driver_inst;
    monitor_master #(.width(width),.n_term(n_term), .bits(bits)) monitor_inst;
    checker_ #(.width(width),.n_term(n_term), .bits(bits)) checker_inst;
    scoreboard #(.width(width),.n_term(n_term), .bits(bits)) scoreboard_inst;
	

	//Mailboxes
	
	comando_tst_agnt_mbx tst_agnt_mbx;
 	comando_agnt_drv_mbx agnt_drv_mbx[n_term];
	comando_drv_chk_mbx drv_chk_mbx;
  	comando_mnt_chk_mbx mnt_chk_mbx;
	comando_chk_scb_mbx chk_scb_mbx;
  	comando_rpt_mbx rpt_mbx;
	function new();
	//intancias de mailboxes
      	for(int j=0; j< n_term; j++)begin
          agnt_drv_mbx[j]=new();
        end
        chk_scb_mbx=new();
	tst_agnt_mbx=new();
	drv_chk_mbx=new();
        mnt_chk_mbx=new();
      	
        
	//intancias de componentes
	agent_inst=new();
	driver_inst=new();
    monitor_inst=new();
    checker_inst=new();
    scoreboard_inst=new();
	
		
		

	//conexion de mailboxes
      
      
     
      for(int j=0; j< n_term; j++)begin
        monitor_inst.monitorc[j].mnt_chk_mbx=mnt_chk_mbx;
        driver_inst.driverc[j].agnt_drv_mbx=agnt_drv_mbx[j];
        driver_inst.driverc[j].drv_chk_mbx=drv_chk_mbx;
        agent_inst.agnt_drv_mbx[j]=agnt_drv_mbx[j];
      end
        scoreboard_inst.rpt_mbx=rpt_mbx;
      	checker_inst.drv_chk_mbx=drv_chk_mbx;
      	checker_inst.mnt_chk_mbx=mnt_chk_mbx;
      	checker_inst.chk_scb_mbx=chk_scb_mbx;
      	scoreboard_inst.chk_scb_mbx=chk_scb_mbx;
	agent_inst.tst_agnt_mbx=tst_agnt_mbx;
		
		
	endfunction


	virtual task run();
      	
	$display("[%g] Ambiente inicializado", $time);
	for(int j=0; j< n_term; j++)begin
          monitor_inst.monitorc[j].fifo.vif=vif;
          driver_inst.driverc[j].fifo.vif=vif;
	end
	fork
	 agent_inst.run();
	 driver_inst.run();
         monitor_inst.run();
         checker_inst.save();
         checker_inst.match();
         scoreboard_inst.run();
	join_none
	endtask
endclass
