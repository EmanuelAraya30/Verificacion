source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh;
rm -rfv `ls | grep -v -E "*\.sv|*\.sh|*\.py"`;
echo Cual es el nombre del test bench
read test
vcs -Mupdate $test -o salida  -full64 -sverilog  -kdb -lca -debug_acc+all -debug_region+cell+encrypt -l log_test +lint=TFIPC-L -cm line+tgl+cond+fsm+branch+assert

