// Implementacion del agente y el generador

class agent #(parameter pckg_sz=16, parameter profundidad=8);
	trans_bus_mbx agnt_drv_mbx;      //Mailbox del agente al driver
	tst_agnt_mbx test_agent_mbx;     //Mailbox del test al agente
	//trans_bus_mbx agnt_chk_mbx;      //Mailbox del agente al checker
	int num_transacciones;
	int max_retardo;
	tipo_trans instruccion;
	bit [pckg_sz-1:0] dto_spec;
	//instrucciones_agente instruccion;
	trans_bus #(.pckg_sz(pckg_sz)) transaccion;
	int cantidad;

task run;
	$display("Se inicializa el agente-generador en tiempo [%g] ",$time);
	begin
	#1
	cantidad = test_agent_mbx.num();
	$display("Numero de pruebas %g",cantidad);	
	if(test_agent_mbx.num() > 0)begin
		$display("[%g] Agente-Generador: se recibe instruccion", $time);
		$display("Numero de transacciones %g",num_transacciones);
		test_agent_mbx.get(instruccion);
		case(instruccion)
		aleatorios:begin
			for (int i=0;i<num_transacciones;i++) begin //
			    $display("[%g] Agente-Generador: se ha escogido la prueba aleatoria", $time);
			    transaccion.new;
			    transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
				transaccion.randomize();
				transaccion.print("Agente-Generador: Transaccion creada");
				agnt_drv_mbx.put(transaccion);
	        end	
		end
		genericos:begin
			for (int i=0;i<num_transacciones;i++) begin
				$display("[%g] Agente-Generador: prueba de envio de paquetes genéricos", $time);
				transaccion=new;
				//transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clki
				transaccion.const_retardo.constraint_mode(1);
				transaccion.const_dispositivos.constraint_mode(1);
				transaccion.const_destino.constraint_mode(1);
				transaccion.const_origen.constraint_mode(1);
				transaccion.randomize();
				transaccion.numero=num_transacciones;
				transaccion.tipo=genericos;
				//transaccion.mensajes=num_transacciones;
				transaccion.D_push={transaccion.Rx,transaccion.dato}; //Uno el dato del destino con el mensaje a enviar 
				transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
				agnt_drv_mbx.put(transaccion);
				transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker");
			end
		end
		//broadcast:begin
			//for (int i=0;i<num_transacciones;i++) begin
			//	$display("[%g] Agente-Generador: se ha escogido la prueba broadcast", $time);
			//	transaccion=new;
			//	transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
			//	transaccion.destino={8{1'b1}}; //Se define que se realice un broadcas
			//	transaccion.mensajes=num_transacciones;
			//	transaccion.randomize();
			//	transaccion.D_push={transaccion.destino,transaccion.dato};
			//	transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
			//	agnt_drv_mbx.put(transaccion);
                          //      transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker");
                            //    agnt_chk_mbx.put(transaccion);

			//end
		//end
		//incorrecta:begin
		//	for (int i=0;i<num_transacciones;i++) begin
		//		$display("[%g] Agente-Generador: se ha escogido la prueba de destino incorrecto", $time);
		//		transaccion=new;
		//		transaccion.max_retardo=max_retardo;// Aleatorizacion de 0 a 20 ciclos de clk
		//		transaccion.mensajes=num_transacciones;
		//		transaccion.randomize();
		//		transaccion.destino=transaccion.dispositivos+destino; //genera una direccion de un dispositivo que no existe
		//		transaccion.D_push={transaccion.destino,transaccion.dato};
		//		transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
                  //              agnt_drv_mbx.put(transaccion);
                    //            transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker"); 
                      //          agnt_chk_mbx.put(transaccion);

			//end
		//end
		//tamano:begin
		//	$display("[%g] Agente-Generador: se ha escogido la prueba de aleatorizacion del tamaño del paquete", $time);

		//	transaccion.new;
		//	transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk

		//	transaccion.randomize();
		//	transaccion.print("Agente: Transaccion creada");
		//	agnt_drv_mbx.put(transaccion);
		//end
		//cantidad:begin
			//transaccion.new;
			//transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
                  //transaccion.randomize();
			//transaccion.print("Agente: Transaccion creada");
			//agnt_drv_mbx.put(transaccion);
		//end
		//multiple:begin
		//	for (int i=0;i<num_transacciones;i++) begin
		//		$display("[%g] Agente-Generador: se ha escogido la prueba de envio a un mismo destino", $time);
		//		transaccion=new;
		//		transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
		//		transaccion.destino=tb.destino;//Se toma el destino defino desde el testbench
		//		transaccion.mensajes=num_transacciones;
		/*		transaccion.randomize();
				transaccion.D_push={transaccion.destino,transaccion.dato};
				transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
                                agnt_drv_mbx.put(transaccion);
                                transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker");
                                agnt_chk_mbx.put(transaccion);
			end
		end
		//cerosunos:begin
		//	for (int i=0;i<num_transacciones;i++) begin
		//		$display("[%g] Agente-Generador: se ha escogido la prueba ceros y unos", $time);
		//		transaccion=new;
		//		transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
		//		transaccion.D_push=testbench.witdh{2'b01};
		//		transaccion.randomize();
		//		transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
                //              agnt_drv_mbx.put(transaccion);
                //              transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker");
                //              agnt_chk_mbx.put(transaccion);
		//	end
		//end
		ceros:begin
			for (int i=0;i<num_transacciones;i++) begin
				$display("[%g] Agente-Generador: se ha escogido la prueba ceros", $time);
				transaccion=new;
				transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
				transaccion.D_push={tb.witdh{1'b0}};
				transaccion.mensajes=num_transacciones;
				transaccion.randomize();
				transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
                                agnt_drv_mbx.put(transaccion);
                                transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker");
                                agnt_chk_mbx.put(transaccion);
			end
		end
		unos:begin
			for (int i=0;i<num_transacciones;i++) begin
				$display("[%g] Agente-Generador: se ha escogido la prueba unos", $time);
				transaccion=new;
				transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
				transaccion.D_push={tb.witdh{1'b1}};
				transaccion.mensajes=num_transacciones;
				transaccion.randomize();
				transaccion.print("Agente-Generador: Transaccion creada y enviada al Driver-Monitor");
                                agnt_drv_mbx.put(transaccion);
                                transaccion.print("Agente-Generador: Transaccion creada y enviada al Checker");
                                agnt_chk_mbx.put(transaccion);

			end
		end
		//reset:begin
		//	transaccion.new;
		//	transaccion.max_retardo=max_retardo; // Aleatorizacion de 0 a 20 ciclos de clk
		//	transaccion.randomize();
		//	transaccion.print("Agente: Transaccion creada");
		//	agnt_drv_mbx.put(transaccion);
		//end*/
		endcase
	end
	end
endtask
endclass

