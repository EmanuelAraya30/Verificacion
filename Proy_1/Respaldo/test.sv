class test #(parameter width=32, parameter n_term=5, parameter bits=1);
  virtual switch_if #(.width(width)) vif [n_term];
	//mailbox
	comando_tst_agnt_mbx tst_agnt_mbx;
	comando_rpt_mbx rpt_mbx;
	//funcion de numero de terminales
	parameter n_transacciones=50;
	parameter retard_max=30;

	//tipo de intruccion
	inst_agnt tipo;
	reporte rpt_inst;
	//Ambiente
    ambiente #(.width(width), .n_term(n_term), .bits(bits)) ambiente_inst;


	function new();	
		tst_agnt_mbx=new();
        rpt_mbx=new();
		ambiente_inst=new();
		ambiente_inst.agent_inst.n_transacciones=n_transacciones;
		ambiente_inst.agent_inst.retard_max=retard_max;
		ambiente_inst.agent_inst.tst_agnt_mbx=tst_agnt_mbx;
        ambiente_inst.scoreboard_inst.rpt_mbx=rpt_mbx;
	endfunction


	task run;
	$display("[%g] Test inicializado", $time);
	fork
	ambiente_inst.run();
	join_none
		

	tipo=trans_aleat;
	tst_agnt_mbx.put(tipo);
	$display("[%g] Transaccion aleatoria con n_transacciones=%g", $time,n_transacciones);
      
      	

      	tipo=broadcast;
	tst_agnt_mbx.put(tipo);
        $display("[%g] Transaccion broadcast con n_transacciones=%g", $time,n_transacciones);
      	
      	tipo=trans_each;
      	tst_agnt_mbx.put(tipo);
      	$display("[%g] Transaccion todos a todos con n_transacciones=%g", $time,n_transacciones);
      
      	tipo=trans_retarmin;
      	tst_agnt_mbx.put(tipo);
        $display("[%g] Transacciones con retardo minimo con n_transacciones=%g", $time,n_transacciones);
      
      	tipo=trans_spec;
      	ambiente_inst.agent_inst.retard_spec=7;
      	ambiente_inst.agent_inst.info_spec=255;
      	ambiente_inst.agent_inst.term_recibo_spec=n_term-1;
      	ambiente_inst.agent_inst.term_envio_spec=2;
      	tst_agnt_mbx.put(tipo);
      	$display("[%g] Transacciones especificas creadas con n_transacciones=%g",$time,n_transacciones);
      	#2000000;
	
	//Se encuentra el ancho de banda de transmision
      	
        ambiente_inst.scoreboard_inst.first=1;
        ambiente_inst.scoreboard_inst.inst_count_bw=0;
        ambiente_inst.scoreboard_inst.tiempo_inicial=0;
        ambiente_inst.scoreboard_inst.tiempo_final=0;
        
      	ambiente_inst.agent_inst.n_transacciones=100;
        ambiente_inst.agent_inst.retard_max=1;
      	tipo=trans_aleat;
		tst_agnt_mbx.put(tipo);
      	#2000000;
      
      	rpt_inst=reporte_bwmax;
      	rpt_mbx.put(rpt_inst);
        #100;
      	ambiente_inst.scoreboard_inst.first=1;
        ambiente_inst.scoreboard_inst.inst_count_bw=0;
        ambiente_inst.scoreboard_inst.tiempo_inicial=0;
        ambiente_inst.scoreboard_inst.tiempo_final=0;
      
        ambiente_inst.agent_inst.n_transacciones=100;    	
      	tipo=trans_spec;
      	ambiente_inst.agent_inst.retard_spec=1;
      	ambiente_inst.agent_inst.info_spec=0;
      	ambiente_inst.agent_inst.term_recibo_spec=0;
      	ambiente_inst.agent_inst.term_envio_spec=n_term-1;
      	tst_agnt_mbx.put(tipo);
      	#2000000;
      
      	rpt_inst=reporte_bwmin;
      	rpt_mbx.put(rpt_inst);
      	rpt_inst=reporte_promedio;
      	rpt_mbx.put(rpt_inst);
      	rpt_inst=reporte_transacciones;
      	rpt_mbx.put(rpt_inst);
	#100;
      	
      	$display("[%g]numero de transacciones realizadas =%g", $time, ambiente_inst.scoreboard_inst.inst_count);
      	$display("Run seed= %d", $get_initial_random_seed());
	$display("Se alcanza el tiempo limite de la prueba");
	$finish;



	endtask

endclass
