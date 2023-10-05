class Checker #(parameter pckg_sz=16, parameter profundidad=8);
	
	trans_bus #(.pckg_sz(pckg_sz)) trans_mntr_chkr; // Transaccion recibida del monitor //Revisar
	trans_bus #(.pckg_sz(pckg_sz)) trans_ag_chkr; // Transaccion recibida del agente //Revisar
	trans_bus #(.pckg_sz(pckg_sz)) to_sb;    // Transaccion para el scoreboard	
	
	trans_bus_mbx mntr_chkr_mbx;
	trans_bus_mbx agnt_chkr_mbx;
	tst_sb_mbx chkr_sb_mbx; //Revisar

    task run;
        $display("[%g] El checker fue inicializado",$time);
        to_sb= new();
        forever begin
            //fork
            mntr_chkr_mbx.get(trans_ch); //Revisar
            agnt_chkr_mbx.get(trans_ag);
            //join
            $display("Checker: Se recibio dato del monitor");
            if(trans_ch.dato == trans_ag.dato)begin
                $display("Checker: Transaccion recibida correctamente");
                to_sb.put(trans_ch);
            end
            else $display("Checker: Error en transacción");
        end
    endtask
endclass	