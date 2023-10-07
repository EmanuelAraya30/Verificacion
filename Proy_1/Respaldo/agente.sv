
class agent #(parameter width=32, parameter n_term=4);
    comando_agnt_drv_mbx agnt_drv_mbx [n_term]; //mailbox de agente a driver
	comando_tst_agnt_mbx tst_agnt_mbx; //mailbox de test a agente
	inst_agnt tipo; //Tipo de test
 	trans_bus #(.width(width), .n_term(n_term)) transaccion; //Objeto en la transaccion
	int n_transacciones; //numero de transacciones
	int retard_max; //retardo maximo
	int retard_spec; //retardo especifico
  	bit [width-13:0] info_spec; //informacion especifica
	bit [3:0] term_envio_spec; //terminal especifica donde se envia
	bit [7:0] term_recibo_spec; //terminal especifica donde se recibe


	task run;
		$display("[%g] El agente fue inicializado", $time);
		forever begin
			#1
			if(tst_agnt_mbx.num()>0)begin //espera una transaccion de test
			$display("[%g] agente recibe una instruccion", $time);
			tst_agnt_mbx.get(tipo);
			case(tipo)
		        trans_aleat:begin //secuencia aleatoria de transacciones
					for(int i=0; i<n_transacciones; i++)begin
						transaccion = new;
						transaccion.retard_max=retard_max;
						transaccion.tipo=tipo;
						transaccion.randomize();
						transaccion.dato={transaccion.term_recibo, transaccion.term_envio, 
						transaccion.info};
						transaccion.print("Agente: transaccion:");
                     	agnt_drv_mbx[transaccion.term_envio].try_put(transaccion);
					end
					
				end
		      broadcast:begin //broadcast
                       for(int i=0; i<n_transacciones; i++)begin
			transaccion = new;
			transaccion.retard_max=retard_max;
			transaccion.tipo=tipo;
			transaccion.randomize();
			transaccion.term_recibo={8{1'b1}};
			transaccion.dato={transaccion.term_recibo, 
		       			  transaccion.term_envio, 
				          transaccion.info};
                        transaccion.term_recibo=0;
			transaccion.print("Agente: transaccion:");
			agnt_drv_mbx[transaccion.term_envio].try_put(transaccion);
		       end
					
		      end
		      trans_each:begin //En cada terminal se hacen envios a todos
		        for(int j=0; j<n_term;j++)begin
					for(int i=0; i<n_term; i++)begin
						transaccion = new;
						transaccion.retard_max=retard_max;
						transaccion.tipo=tipo;
						transaccion.randomize();
						transaccion.term_recibo=i;
						transaccion.term_envio=j;
						transaccion.dato={transaccion.term_recibo, 
						transaccion.term_envio, 
						transaccion.info};
						if(j!=i)begin //para que no se envie a si mismo
							transaccion.print("Agente: transaccion:");
							agnt_drv_mbx[transaccion.term_envio].try_put(transaccion);
						end
					end
				end
		      end
			  trans_retarmin:begin
				for(int i=0; i<n_transacciones; i++)begin
					transaccion = new;
					transaccion.retard_max=retard_max;
					transaccion.tipo=tipo;
					transaccion.randomize();
					transaccion.retardo=1;
					transaccion.dato={transaccion.term_recibo, 
					transaccion.term_envio, 
					transaccion.info};
					transaccion.print("Agente: transaccion:");
					agnt_drv_mbx[transaccion.term_envio].try_put(transaccion);
				end
			  end
			  trans_spec:begin //Transacciones especificas
                       for(int i=0; i<n_transacciones; i++)begin
			transaccion = new;
			transaccion.retardo=retard_spec;
			transaccion.tipo=tipo;
			transaccion.info=info_spec;
			transaccion.term_recibo=term_recibo_spec;
			transaccion.term_envio=term_envio_spec;
			transaccion.dato={transaccion.term_recibo, 
					  transaccion.term_envio, 
					  transaccion.info};
	                transaccion.print("Agente: transaccion:");
			agnt_drv_mbx[transaccion.term_envio].try_put(transaccion);
                       end
		      end				    
		endcase
		end
		end
	endtask
endclass

