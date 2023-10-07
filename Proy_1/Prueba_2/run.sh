#source synopsys_tools.sh;
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh;
rm -rfv ls |grep -v ".*\.sv\|.*\.sh";

rm -r cm.log csrc/ .fsm.sch.verilog.xml log_test salida salida.daidir/ salida.vdb/ ucli.key;

vcs -Mupdate testbench.sv -o salida -full64 -debug_all -sverilog -l log_test +lint=TFIPC-L -kdb -cm line+tgl+cond+fsm+branch+assert;

./salida -cm line+tgl+cond+fsm+branch+assert;
#dve -full64 -covdir salida.vdb &
#Verdi -cov -covdir salida.vdb
