class scoreboard #(parameter pckg_sz=16);
    trans_sb_mbx chkr_sb_mbx;
	tst_agnt_mbx tst_sb_mbx;
	trans_sb #(.pckg_sz(pckg_sz)) transaccion_entrante;
	trans_sb scoreboard[$];     // Estructura dinamica
	trans_sb aux[$];  // Estructura dinamica auxiliar para explorar el scoreboard
	trans_sb aux_trans;
	shortreal ret_prom;
	shortreal AB_prom;
	solicitud_sb orden;
	int tam_sb = 0;
	int transac_comp = 0;
	int ret_tot = 0;
	int AB_tot = 0;
	
task run;
	$display("[%g] El scoreboard fue inicializado",$time);
	forever begin
		#5
		if(chkr_sb_mbx.numero()>0)begin //Revisar
			chkr_sb_mbx.get(transaccion_entrante);
			transaccion_entrante.print("Scoreboard: Transaccion del checker recibida");
			if(transaccion_entrante.completado)begin
				ret_tot = ret_tot + transaccion_entrante.latencia;
				AB_tot = AB_tot + 1/transaccion_entrante.latencia;
				transac_comp++;
			end
			scoreboard.push_back(transaccion_entrante);
		end else begin 
			if(tst_sb_mbx.numero()>0)begin
				case(orden)
					// Reporte completo
					rep_compl:begin
					$display("Scoreboard: Solicitud de reporte completo");
					tam_sb=this.scoreboard.size();
					for(int i=0;i<tam_sb;i++)begin
						aux_trans=scoreboard.pop_front;
						aux_trans.print("Scoreboard reporte:");
						aux.push_back(aux_trans);
					end
					scoreboard=aux;
					end

					// Retardo promedio
					ret_prom:begin
					$display("Scoreboard: Solicitud de retardo promedio");
					ret_prom = ret_tot/transac_comp;
					$display("[%g] Scoreboard: El retardo promedio es %0.3f", $time, ret_prom);
					end
			
					// Ancho de banda promedio
					bw_prom:begin
					$display("Scoreboard: Solicitud de ancho de banda promedio");
					AB_prom = AB_tot/transac_comp;
					$display("[%g] Scoreboard: El ancho de banda promedio es %0.3f", $time, AB_prom);
					end

					default: $display("[%g] Scoreboard: Error en solicitud");
				endcase
			end
		end
	end
endtask
endclass
