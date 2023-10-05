
class ambiente #(parameter pckg_sz=16, parameter profundidad=8, parameter drvrs=16, parameter bits=1); // Parametros se definen en el test
	// Declaracion de los componentes (dispotivos, bloques) del ambiente
	driver #(.pckg_sz(pckg_sz), .profundidad(profundidad), .drvrs(drvrs), .bits(bits)) driver_inst;
	monitor #(.pckg_sz(pckg_sz), .profundidad(profundidad), .drvrs(drvrs), .bits(bits)) monitor_inst;
	//checker #(.pckg_sz(pckg_sz), .profundidad(profundidad)) checker_inst;
	//scoreboard #(.pckg_sz(pckg_sz)) scoreboard_inst;
	agent #(.pckg_sz(pckg_sz), .profundidad(profundidad)) agent_inst;

	int num_transacciones;

	// Declaracion de la interface que conecta el DUT
	virtual bus_if #(.pckg_sz(pckg_sz), .profundidad(profundidad), .drvrs(drvrs), .bits(bits)) _if;
	
	// Declaracion de los mailboxes
	trans_bus_mbx agnt_drv_mbx;        //Mailbox del agente al driver
	//trans_bus_mbx agnt_chkr_mbx;        //Mailbox del agente al checker
	//trans_bus_mbx mntr_chkr_mbx;        //Mailbox del driver al checker
	//trans_scoreboard_mbx chkr_sb_mbx;  //Mailbox del checker al scoreboard
	//test_scoreboard_mbx tst_sb_mbx;    //Mailbox del test al scoreboard
	tst_agnt_mbx test_agent_mbx;       //Mailbox del test al agente
	
	function new();
		// Instanciacion de los mailboxes
		//mntr_chkr_mbx   = new();
		agnt_drv_mbx   = new();
		//chkr_sb_mbx    = new();
		//tst_sb_mbx     = new();
		test_agent_mbx   = new();
		//agnt_chkr_mbx  = new();

		// Instalacion de los componenetes del ambiente
		driver_inst     = new();
		//checker_inst    = new();
		//scoreboard_inst = new();
		agent_inst      = new();
		monitor_inst    = new();

		// Conexion de las interfaces y los mailboxes en el ambiente
		driver_inst.vif             = _if;
		monitor_inst.vif            = _if;
		driver_inst.agnt_drv_mbx    = agnt_drv_mbx;
		//monitor_inst.mntr_chkr_mbx   =mntr_chkr_mbx;
		//checker_inst.drv_chkr_mbx   = drv_chkr_mbx;
		//checker_inst.agnt_chk_mbx   = agnt_chk_mbx;
		//checker_inst.chkr_sb_mbx    = chkr_sb_mbx;
		//scoreboard_inst.chkr_sb_mbx = chkr_sb_mbx;
		//scoreboard_inst.tst_sb_mbx  = tst_sb_mbx;
		agent_inst.test_agent_mbx      = test_agent_mbx;
		agent_inst.agnt_drv_mbx      = agnt_drv_mbx;
		agent_inst.num_transacciones = num_transacciones;
		//agent_inst.randomize();
		//agent_inst.agnt_chkr_mbx     = agnt_chkr_mbx;
	endfunction

	virtual task run();
		$display("[%g] El ambiente fue inicializado",$time);
		fork
			agent_inst.run();
			driver_inst.run();
			//checker_inst.run();
			//scoreboard_inst.run();
			monitor_inst.run();
		join_none
	endtask
endclass
