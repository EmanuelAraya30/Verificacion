// Implementacion del test

class test #(parameter pckg_sz=16, parameter profundidad=8, parameter drvrs=4, parameter bits=1);
	//test_scoreboard_mbx tst_sb_mbx;
	test_agent_mbx tst_agnt_mbx;

	rand int num_transacciones;
	parameter max_retardo = 20;
	
	constraint const_num{num_transacciones<20; num_transacciones>3;}

	solicitud_sb orden;
	tipo_trans instruccion_agente;
	solicitud_sb instruccion_sb;
	
	// Definicion del ambiente
	ambiente #(.profundidad(profundidad), .pckg_sz(pckg_sz), .drvrs(drvrs), .bits(bits)) ambiente_inst;
	// Definicion de la interfaz a la que se conecta el DUT
	virtual bus_if #(.pckg_sz(pckg_sz), .bits(bits), .drvrs(drvrs)) _if;
	// Definicion de las condiciones iniciales del test
	
function new;
	// Instanciacion de los mailboxes
	tst_agnt_mbx = new();
	// Definicion y conexion del driver
	ambiente_inst = new();
	ambiente_inst._if = _if;
	//environment_inst.tst_sb_mbx = tst_sb_mbx;
	//environment_inst.scoreboard_inst.tst_sb_mbx = tst_sb_mbx;
	ambiente_inst.tst_agnt_mbx = tst_agnt_mbx;
	ambiente_inst.agent_inst.tst_agnt_mbx = tst_agnt_mbx;
endfunction

task run;
	$display("Se inicializa el test en el tiempo [%g]",$time);
	$display("Numero de transacciones",num_transacciones);	
	ambiente_inst.agent_inst.num_transacciones = num_transacciones;
	ambiente_inst.num_transacciones = num_transacciones;
	fork
		ambiente_inst.run();
	join_none
	
	// 1) Aleatorios
	//instr_agent = aleatorios;
	//tst_agnt_mbx.put(instr_agent);
	//$display("[%g] Test: Instruccion aleatorios enviada, num_transacciones %g",$time,num_transacciones);
	
	// 2) Genericos
	instruccion_agente = genericos;
	tst_agnt_mbx.put(instruccion_agente);
	$display("[%g] Test: Instruccion genericos enviada, num de transacciones %g",$time,num_transacciones);
	/*
	// 3) Broadcast
	instr_agent = broadcast;
	tst_agnt_mbx.put(instr_agent);
	$display("[%g] Test: Instruccion broadcast enviada, num_transacciones %g",$time,num_transacciones);
	
	// 4) Incorrecta
	// Especificar direccion incorrecta
	instr_agent = incorrecta;
	tst_agnt_mbx.put(instr_agent);
	$display("[%g] Test: Instruccion incorrecta enviada, num_transacciones %g",$time,num_transacciones);
	
	// 5) Tamano de paquete
	// Especificar tamano de paquete
	//instr_agent = tamano;
	//tst_agnt_mbx.put(instr_agent);
	//$display("[%g] Test: Instruccion tamano enviada, num_transacciones %g",$time,num_transacciones);
	
	// 6) Cantidad paquete
	// Especificar cantidad de paquetes
	//instr_agent = cantidad;
	//tst_agnt_mbx.put(instr_agent);
	//$display("[%g] Test: Instruccion cantidad enviada, num_transacciones %g",$time,num_transacciones);
	
	// 7) Multiples dispositivos al mismo tiempo
	instr_agent = multiple;
	tst_agnt_mbx.put(instr_agent);
	$display("[%g] Test: Instruccion multiple enviada, num_transacciones %g",$time,num_transacciones);

	// 8) Enviar ceros y unos
	// Especificar el dato especifico 01010101...
	//instr_agent = cerosunos;
	//tst_agnt_mbx.put(instr_agent);
	//$display("[%g] Test: Instruccion cerosunos enviada, num_transacciones %g",$time,num_transacciones);
	
	// 9) Enviar ceros
	// Especificar el dato especifico 00000000...
	instr_agent = ceros;
	tst_agnt_mbx.put(instr_agent);
	$display("[%g] Test: Instruccion ceros enviada, num_transacciones %g",$time,num_transacciones);

	// 10) Enviar unos
	// Especificar el dato especifico 11111111...
	instr_agent = unos;
	tst_agnt_mbx.put(instr_agent);
	$display("[%g] Test: Instruccion unos enviada, num_transacciones %g",$time,num_transacciones);

	// 11) Reset aleatorio
	//instr_agent = reset;
	//tst_agnt_mbx.put(instr_agent);
	//$display("[%g] Test: Instruccion reset enviada, num_transacciones %g",$time,num_transacciones);
	*/
endtask
endclass	

