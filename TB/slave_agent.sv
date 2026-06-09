# code for slv_agt.sv

...
class slv_agt extends uvm_agent;
	`uvm_component_utils(slv_agt)

	slv_drv drv_h;
	slv_mon mon_h;
	slv_seqr seqr_h;
	slv_agt_cfg s_cfg;
	
	function new(string name="slv_agt", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	if(!uvm_config_db#(slv_agt_cfg)::get(this,"","slv_agt_cfg",s_cfg))
		`uvm_fatal("in slv_agt","getting failed")

	mon_h=slv_mon::type_id::create("mon_h",this);

	if(s_cfg.is_active==UVM_ACTIVE)
	begin
		drv_h=slv_drv::type_id::create("drv_h",this);
		seqr_h=slv_seqr::type_id::create("seqr_h",this);
	end
	endfunction
	
	function void connect_phase(uvm_phase phase);
                if(s_cfg.is_active==UVM_ACTIVE)
                drv_h.seq_item_port.connect(seqr_h.seq_item_export);
        endfunction
endclass
...


# code for slv_agt_cfg.sv


  ...
  class slv_agt_cfg extends uvm_object;
	`uvm_object_utils(slv_agt_cfg)

	uvm_active_passive_enum is_active=UVM_ACTIVE;
	
	function new(string name="slv_agt_cfg");
		super.new(name);
	endfunction

	virtual ahb_if vif;
endclass
...


# code for slv_agt_top.sv


  ...
  class slv_agt_top extends uvm_env;
	`uvm_component_utils(slv_agt_top)

	env_cfg e_cfg;
	slv_agt_cfg s_cfg;
	slv_agt s_agt[];
	
	function new(string name="slv_agt_top", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

	if(!uvm_config_db#(env_cfg)::get(this,"","env_cfg",e_cfg))
		`uvm_fatal("in_slv_top","getting failed")
	
	if(e_cfg.has_slv_agt)
	begin
		s_agt=new[e_cfg.no_of_slv_agt];
		foreach(s_agt[i])
		begin
			uvm_config_db#(slv_agt_cfg)::set(this,$sformatf("s_agt[%0d]*",i),"slv_agt_cfg",e_cfg.s_cfg[i]);
			s_agt[i]=slv_agt::type_id::create($sformatf("s_agt[%0d]",i),this);
		end
	end
	endfunction
endclass
...


# code for slv_drv.sv


  ...
  class slv_drv extends uvm_driver#(ahb_xtn);
	`uvm_component_utils(slv_drv)
	

	virtual ahb_if.SLV_DRV_MP vif;
	slv_agt_cfg s_cfg;

	int slv_drv_cnt;

	function new(string name="slv_drv", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db#(slv_agt_cfg)::get(this,"","slv_agt_cfg",s_cfg))
			`uvm_fatal("IN SLV DRV", "getting failed")
	endfunction

	function void connect_phase(uvm_phase phase);
		vif=s_cfg.vif;
	endfunction


	task run_phase(uvm_phase phase);   //reset
	//	vif.slv_drv_cb.HREADY<=1;
	//	$display("slv drv");
		forever
		begin
			seq_item_port.get_next_item(req);
			//$display("slv drv2");

			send_to_dut(req);
			seq_item_port.item_done();
		end
	endtask

	task send_to_dut(ahb_xtn req);
//$display("slv drv1");

	//	@(vif.slv_drv_cb)
		//$display("resp_slv %d",req.resp_slv);
		if(req.resp_slv==0)
		begin
			vif.slv_drv_cb.HREADY<=1;
			vif.slv_drv_cb.HRESP<=0;

			@(vif.slv_drv_cb)
			if(vif.slv_drv_cb.HWRITE==0)
			vif.slv_drv_cb.HRDATA<=req.HRDATA;
		end
	
		if(req.resp_slv==1)
		begin
			vif.slv_drv_cb.HREADY<=0;
			vif.slv_drv_cb.HRESP<=0;
			repeat(req.delay)
			@(vif.slv_drv_cb);
			
			vif.slv_drv_cb.HREADY<=1;
			vif.slv_drv_cb.HRESP<=0;

			@(vif.slv_drv_cb);			
			if(vif.slv_drv_cb.HWRITE==0)
			vif.slv_drv_cb.HRDATA<=req.HRDATA;
		end

		if(req.resp_slv==2)
                begin
                        vif.slv_drv_cb.HREADY<=0;
                        vif.slv_drv_cb.HRESP<=1;
                        @(vif.slv_drv_cb);
                        vif.slv_drv_cb.HREADY<=1;
                        vif.slv_drv_cb.HRESP<=1;
                        @(vif.slv_drv_cb);
                        if(vif.slv_drv_cb.HWRITE==0)
                        vif.slv_drv_cb.HRDATA<=req.HRDATA;
                end

		slv_drv_cnt++;
		$display("Slave driver count: %0d",slv_drv_cnt);

	`uvm_info("slv_drv",req.sprint(),UVM_LOW)

	endtask
endclass
...


# code for slv_mon.sv


  ...
  class slv_mon extends uvm_monitor;
	`uvm_component_utils(slv_mon)
	
	virtual ahb_if.SLV_MON_MP vif;
	slv_agt_cfg s_cfg;
	uvm_analysis_port#(ahb_xtn) ap;
	ahb_xtn req;

	int slv_mon_cnt;

	function new(string name="slv_mon", uvm_component parent);
		super.new(name,parent);
		ap=new("ap",this);
		req=ahb_xtn::type_id::create("req");
	endfunction

	function void build_phase(uvm_phase phase);
			if(!uvm_config_db#(slv_agt_cfg)::get(this,"","slv_agt_cfg",s_cfg))
			`uvm_fatal("IN SLV MON", "getting failed")
	endfunction

	function void connect_phase(uvm_phase phase);
		vif=s_cfg.vif;
	endfunction

	task run_phase(uvm_phase phase);
		forever
		begin
			collect_data();
		end
	endtask

	task collect_data();
		wait(vif.slv_mon_cb.HREADY && (vif.slv_mon_cb.HTRANS==2'b10 || vif.slv_mon_cb.HTRANS==2'b11))   //ready
			req.HADDR=vif.slv_mon_cb.HADDR;
			req.HSIZE=vif.slv_mon_cb.HSIZE;
			req.HBURST=vif.slv_mon_cb.HBURST;
			req.HWRITE=vif.slv_mon_cb.HWRITE;
			req.HTRANS=vif.slv_mon_cb.HTRANS;
			req.HRESP=vif.slv_mon_cb.HRESP;
			req.HREADY=vif.slv_mon_cb.HREADY;


		@(vif.slv_mon_cb);
		wait(vif.slv_mon_cb.HREADY)
		if(vif.slv_mon_cb.HWRITE)
			req.HWDATA=vif.slv_mon_cb.HWDATA;
		else
			req.HRDATA=vif.slv_mon_cb.HRDATA;

		slv_mon_cnt++;
                $display("Slave monitor count: %0d",slv_mon_cnt);

	`uvm_info("slv_mon",req.sprint(),UVM_LOW)

	ap.write(req);
	endtask
endclass
...


# code for slv_seqr.sv


  ...
  class slv_seqr extends uvm_sequencer#(ahb_xtn);
	`uvm_component_utils(slv_seqr)
	
	function new(string name="slv_seqr",uvm_component parent);
		super.new(name,parent);
	endfunction
endclass
...


# code for slv_seqs.sv


  ...
  class slv_seqs extends uvm_sequence#(ahb_xtn);
	`uvm_object_utils(slv_seqs)
	bit [9:0]length;
	
	function new(string name="slv_seqs");
		super.new(name);
	endfunction
endclass

class okay extends slv_seqs;
	`uvm_object_utils(okay)
	
	function new(string name="okay");
		super.new(name);
	endfunction
	
	task body();

		req=ahb_xtn::type_id::create("req");

		#60;
	
		if(!uvm_config_db#(bit[9:0])::get(null,get_full_name(),"length",length))
		`uvm_fatal("in okay seqs","getting length failed!!")
//$display("length %d",length);
		repeat(length)
		begin
			start_item(req);
			assert(req.randomize() with {resp_slv==0;});
			finish_item(req);
		end
	endtask
endclass

class okay_with_wait_state extends slv_seqs;
	`uvm_object_utils(okay_with_wait_state)
	
	function new(string name="okay_with_wait_state");
		super.new(name);
	endfunction
	
	task body();

		req=ahb_xtn::type_id::create("req");

		#60;
	
		if(!uvm_config_db#(bit[9:0])::get(null,get_full_name(),"length",length))
		`uvm_fatal("in okay with wait seqs","getting length failed!!")

		repeat(length)
		begin
			start_item(req);
			assert(req.randomize() with {resp_slv==1;});
			finish_item(req);
		end
	endtask
endclass

class error extends slv_seqs;
	`uvm_object_utils(error)
	
	function new(string name="error");
		super.new(name);
	endfunction
	
	task body();

		req=ahb_xtn::type_id::create("req");

		#60;
	
		if(!uvm_config_db#(bit[9:0])::get(null,get_full_name(),"length",length))
		`uvm_fatal("in error seqs","getting length failed!!")

		repeat(length)
		begin
			start_item(req);
			assert(req.randomize() with {resp_slv==2;});
			finish_item(req);
		end
	endtask
endclass
...


