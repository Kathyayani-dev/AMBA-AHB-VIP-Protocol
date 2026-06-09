# code for ahb_pkg.sv


  ...
  package ahb_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	`include "mstr_agt_cfg.sv"
	`include "slv_agt_cfg.sv"
	`include "env_cfg.sv"

	`include "ahb_xtn.sv"

	`include "mstr_seqs.sv"
	`include "mstr_seqr.sv"
	`include "mstr_drv.sv"
	`include "mstr_mon.sv"
	`include "mstr_agt.sv"
	`include "mstr_agt_top.sv"

	`include "slv_seqs.sv"
	`include "slv_seqr.sv"
	`include "slv_drv.sv"
	`include "slv_mon.sv"
	`include "slv_agt.sv"
	`include "slv_agt_top.sv"

	`include "sb.sv"

	`include "env.sv"
	`include "ahb_test.sv"
endpackage
...


# code for ahb_test.sv


  ...
  class ahb_test extends uvm_test;
	`uvm_component_utils(ahb_test)

	env env_h;
	env_cfg e_cfg;
	mstr_agt_cfg m_cfg[];
	slv_agt_cfg s_cfg[];
	
	int no_of_mstr_agt=1;
	int no_of_slv_agt=1;
	bit has_sb=1;
	bit has_mstr_agt=1;
	bit has_slv_agt=1;

	function new(string name="ahb_test", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
		e_cfg = env_cfg::type_id::create("e_cfg");

		e_cfg.no_of_mstr_agt=this.no_of_mstr_agt;
		e_cfg.no_of_slv_agt=this.no_of_slv_agt;
		e_cfg.has_mstr_agt=this.has_mstr_agt;
		e_cfg.has_slv_agt=this.has_slv_agt;
		e_cfg.m_cfg=new[no_of_mstr_agt];
		e_cfg.s_cfg=new[no_of_slv_agt];

	
		if(e_cfg.has_mstr_agt)
		begin
			m_cfg=new[no_of_mstr_agt];
			foreach(m_cfg[i])
			begin
				m_cfg[i]=mstr_agt_cfg::type_id::create($sformatf("m_cfg[%0d]",i));
				m_cfg[i].is_active=UVM_ACTIVE;
				if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_if",m_cfg[i].vif))
						`uvm_fatal("IN TEST", "getting failed")
				e_cfg.m_cfg[i]=m_cfg[i];
			end
		end
		
		if(e_cfg.has_slv_agt)
		begin
			s_cfg=new[no_of_slv_agt];
			foreach(s_cfg[i])
			begin
				s_cfg[i]=slv_agt_cfg::type_id::create($sformatf("s_cfg[%0d]",i));
				s_cfg[i].is_active=UVM_ACTIVE;
				if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_if",s_cfg[i].vif))
					`uvm_fatal("IN TEST", "getting failed")
				e_cfg.s_cfg[i]=s_cfg[i];
			end
		end

		uvm_config_db#(env_cfg)::set(this,"*","env_cfg",e_cfg);
		env_h=env::type_id::create("env_h",this);
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		uvm_top.print_topology();
	endfunction

endclass

class single_trans extends ahb_test;
	`uvm_component_utils(single_trans)

	function new(string name="single_trans", uvm_component parent);
		super.new(name, parent);
	endfunction

	single_seqs ss;
	okay os;
	okay_with_wait_state ows;
	error e;
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ss=single_seqs::type_id::create("ss");
		os=okay::type_id::create("os");
	//	ows=okay_with_wait_state::type_id::create("ows");
	//	e=error::type_id::create("e");		
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		fork
		ss.start(env_h.m_top.m_agt[0].seqr_h);
		os.start(env_h.s_top.s_agt[0].seqr_h);
		//ows.start(env_h.s_top.s_agt[0].seqr_h);
		//e.start(env_h.s_top.s_agt[0].seqr_h);
		join
		phase.drop_objection(this);
	endtask
endclass

class incr_trans extends ahb_test;
	`uvm_component_utils(incr_trans)

	function new(string name="incr_trans", uvm_component parent);
		super.new(name, parent);
	endfunction

	incr_seqs is;
	okay os;
	okay_with_wait_state ows;
	error e;
		
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		is=incr_seqs::type_id::create("is");
		os=okay::type_id::create("os");
		//ows=okay_with_wait_state::type_id::create("ows");
		//e=error::type_id::create("e");		
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		fork
		is.start(env_h.m_top.m_agt[0].seqr_h);
		os.start(env_h.s_top.s_agt[0].seqr_h);
		//ows.start(env_h.s_top.s_agt[0].seqr_h);
		//e.start(env_h.s_top.s_agt[0].seqr_h);
		join
		phase.drop_objection(this);
	endtask
endclass

class wrap_trans extends ahb_test;
	`uvm_component_utils(wrap_trans)

	function new(string name="wrap_trans", uvm_component parent);
		super.new(name, parent);
	endfunction

	wrap_seqs ws;
	okay os;
	okay_with_wait_state ows;
	error e;
		
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ws=wrap_seqs::type_id::create("ws");
		os=okay::type_id::create("os");
		ows=okay_with_wait_state::type_id::create("ows");
		e=error::type_id::create("e");		
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
	endfunction

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);
		fork
		ws.start(env_h.m_top.m_agt[0].seqr_h);
		os.start(env_h.s_top.s_agt[0].seqr_h);
		ows.start(env_h.s_top.s_agt[0].seqr_h);
		e.start(env_h.s_top.s_agt[0].seqr_h);
		join
		phase.drop_objection(this);
	endtask
endclass
...
