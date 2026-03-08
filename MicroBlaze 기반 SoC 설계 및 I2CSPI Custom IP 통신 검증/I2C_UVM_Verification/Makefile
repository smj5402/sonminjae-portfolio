RTL_DIR = ./rtl
TB_DIR = ./testbench
BUILD_DIR = ./build
INC_DIR = +incdir+$(RTL_DIR)
SIMV = ./build/simv

COMP_OPT = -full64 -sverilog $(INC_DIR) \
-debug_access+all -kdb -lca \
-timescale=1ns/100ps \
-ntb_opts uvm-1.2 \
-cm line+cond+fsm+tgl+branch+assert \
+vcs+fsdb \
-o $(BUILD_DIR)/simv

SIMV_OPT = -cm line+cond+fsm+tgl+branch+assert \
	-cm_dir coverage.vdb \
	-cm_name sim1

SIGNAL = axi.rc

all: vcs simv verdi

generate_f:
	mkdir -p $(BUILD_DIR)
	find ./rtl ./testbench \( -name "*.v" -o -name "*.sv" \) > ./build/files.f

vcs: generate_f
	vcs $(COMP_OPT) -f $(BUILD_DIR)/files.f

simv:
	export NOVAS_FSDB_ENV_DUMP_SEQ_NUM=on; $(SIMV) $(SIMV_OPT)

verdi:
	verdi -dbdir $(BUILD_DIR)/simv.daidir -ssf $(BUILD_DIR)/wave.fsdb -sswr $(SIGNAL) -cov -covdir coverage.vdb &

clean:
	rm -rf $(BUILD_DIR) csrc novas. ucli.key verdiLog files.f inter* .inter* .vcs* .h tr_db.log.conf sysBusyPLog

.PHONY: all generate_f vcs simv verdi clean

##verdi -cov -coverage.vdb