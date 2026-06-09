# code for top.sv


  ...
  module top;
	import ahb_pkg::*;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	bit clk;
	always #5 clk = ~clk;

	ahb_if AHB_IF(clk);

	initial
	begin	
		uvm_config_db#(virtual ahb_if)::set(null,"*","ahb_if",AHB_IF);
		run_test();
	end

	property p1;
	    	@(posedge AHB_IF.HCLK) (!AHB_IF.HREADY)|=> $stable(AHB_IF.HADDR) && $stable(AHB_IF.HBURST) && $stable(AHB_IF.HSIZE) && $stable(AHB_IF.HTRANS) && $stable(AHB_IF.HWRITE);
	endproperty

    	AP1: assert property (p1);
    	CP1: cover property(p1);

endmodule
...


#code for env.sv


  ...
  class env extends uvm_env;
	`uvm_component_utils(env)
	
	env_cfg e_cfg;
	mstr_agt_top m_top;
	slv_agt_top s_top;
	sb sb_h;

	function new(string name="env", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		if(!uvm_config_db#(env_cfg)::get(this,"","env_cfg",e_cfg))
			`uvm_fatal("in env","getting failed")

		m_top=mstr_agt_top::type_id::create("m_top",this);
		s_top=slv_agt_top::type_id::create("s_top",this);
		sb_h=sb::type_id::create("sb_h",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		m_top.m_agt[0].mon_h.ap.connect(sb_h.mstr_fifo.analysis_export);
		s_top.s_agt[0].mon_h.ap.connect(sb_h.slv_fifo.analysis_export);
	endfunction
endclass
...


# code for env_cfg.sv


  ...
  class env_cfg extends uvm_object;
	`uvm_object_utils(env_cfg)

	mstr_agt_cfg m_cfg[];
	slv_agt_cfg s_cfg[];

	int no_of_mstr_agt=1;
	int no_of_slv_agt=1;
	int has_mstr_agt=1;
	int has_slv_agt=1;
	
	function new(string name="env_cfg");
		super.new(name);
	endfunction
endclass
...


# code for ahb_xtn.sv


  ...
  class ahb_xtn extends uvm_sequence_item;
	`uvm_object_utils(ahb_xtn)

	function new(string name="ahb_xtn");
		super.new(name);
	endfunction
	
	    
	rand bit [31:0]HADDR;
	rand bit [31:0]HWDATA;
	rand bit [31:0]HRDATA;
 	rand bit [2:0] HBURST;
	rand bit [2:0] HSIZE;
	rand bit [1:0] HTRANS;
	rand bit       HWRITE;
	rand bit       HRESP;
	rand bit       HREADY;
	rand bit [9:0] length;
	rand bit [2:0] delay;

	rand enum{okay, okay_with_wait_state, error} resp_slv;
	
	constraint valid_addr_range {HADDR inside {[0:200]};}     //constraints
	constraint valid_data_size  {HSIZE inside {[0:2]};}
	constraint valid_data  {HWDATA inside {[0:200]};}
	constraint valid_write {HWRITE==1;}

	constraint valid_addr_align {HSIZE==1 -> HADDR[0]==0;
				     HSIZE==2 -> HADDR[1:0]==2'b00;}
	constraint valid_length     {if(HBURST==0)  length==1;
				else if(HBURST==2)  length==4;   //wrap4
			        else if(HBURST==3)  length==4;   //incr4
			        else if(HBURST==4)  length==8;   //wrap8
			        else if(HBURST==5)  length==8;   //incr8
			        else if(HBURST==6)  length==10;  //wrap16
			        else if(HBURST==7)  length==10;} //incr16


	function void do_print(uvm_printer printer);
	//	super.do_print(printer);
	//	$display("hello");
		printer.print_field("HADDR",this.HADDR,32,UVM_DEC);
		printer.print_field("HWDATA",this.HWDATA,32,UVM_DEC);
		printer.print_field("HRDATA",this.HRDATA,32,UVM_DEC);
		printer.print_field("HBURST",this.HBURST,3,UVM_DEC);
		printer.print_field("HSIZE",this.HSIZE,3,UVM_DEC);
		printer.print_field("HTRANS",this.HTRANS,2,UVM_DEC);
		printer.print_field("HWRITE",this.HWRITE,1,UVM_DEC);
		printer.print_field("HRESP",this.HRESP,1,UVM_DEC);
		printer.print_field("HREADY",this.HREADY,1,UVM_DEC);
	endfunction
endclass
...


# code for sb.sv


  ...
  class sb extends uvm_scoreboard;
	`uvm_component_utils(sb)

	uvm_tlm_analysis_fifo#(ahb_xtn) mstr_fifo;
	uvm_tlm_analysis_fifo#(ahb_xtn) slv_fifo;

	ahb_xtn mstr_xtn;
	ahb_xtn slv_xtn;

	ahb_xtn mstr_cov_data;
	ahb_xtn slv_cov_data;

	static int addr_same, addr_not_same;
	static int wdata_same, wdata_not_same;
	static int rdata_same, rdata_not_same;

	covergroup mstr_covergroup;
		option.per_instance=1;
		Hwrite : coverpoint mstr_cov_data.HWRITE {bins hwrite={0,1};}
		Hburst : coverpoint mstr_cov_data.HBURST {bins hburst={[0:7]};}
		Htrans : coverpoint mstr_cov_data.HTRANS {bins htrans={2,3};}
		Hsize  : coverpoint mstr_cov_data.HSIZE  {bins hsize={0,1,2};}
		Haddr  : coverpoint mstr_cov_data.HADDR  {bins haddr={[0:200]};}
		Hwdata : coverpoint mstr_cov_data.HWDATA {bins hwdata={[0:200]};}
	endgroup

	covergroup slv_covergroup;
		option.per_instance=1;
		Hrdata : coverpoint slv_cov_data.HRDATA {bins hrdata={[0:200]};}
		Hresp  : coverpoint slv_cov_data.HRESP  {bins hresp={0,1};}
		Hready : coverpoint slv_cov_data.HREADY {bins hready={0,1};}
	endgroup		

	function new(string name="sb", uvm_component parent);
		super.new(name,parent);

		mstr_fifo=new("mstr_fifo",this);
		slv_fifo=new("slv_fifo",this);

		mstr_covergroup=new();
		slv_covergroup=new();
	endfunction

	task run_phase(uvm_phase phase);
		forever
		begin
			mstr_fifo.get(mstr_xtn);
		//	`uvm_info("mstr_trans",mstr_xtn.sprint, UVM_LOW)
			mstr_cov_data=new mstr_xtn;
			mstr_covergroup.sample();

			slv_fifo.get(slv_xtn);
		//	`uvm_info("slv_trans",slv_xtn.sprint, UVM_LOW)

			slv_cov_data=new slv_xtn;
			slv_covergroup.sample();

			compare_data(mstr_xtn, slv_xtn);
		end
	endtask
	
	task compare_data(ahb_xtn mstr_xtn, ahb_xtn slv_xtn);
		if(mstr_xtn.HADDR==slv_xtn.HADDR)
		begin
			addr_same++;
			$display("same mstr_xtn.HADDR=%0d | slv_xtn.HADDR=%0d", mstr_xtn.HADDR,slv_xtn.HADDR);
		end
		else
		begin
			addr_not_same++;
			$display("mismatch mstr_xtn.HADDR=%0d | slv_xtn.HADDR=%0d", mstr_xtn.HADDR,slv_xtn.HADDR);
		end
		
	/*-----------------------------------------------------------------------------------------------------*/

		if(mstr_xtn.HWRITE)
		begin
			if(mstr_xtn.HWDATA==slv_xtn.HWDATA)
			begin
				wdata_same++;
				$display("same mstr_xtn.HWDATA=%0d | slv_xtn.HWDATA=%0d", mstr_xtn.HWDATA,slv_xtn.HWDATA);
			end
			else
			begin
				wdata_not_same++;
				$display("mismatch mstr_xtn.HWDATA=%0d | slv_xtn.HWDATA=%0d", mstr_xtn.HWDATA,slv_xtn.HWDATA);
			end
		end
		else
		begin
			if(mstr_xtn.HRDATA==slv_xtn.HRDATA)
			begin
				rdata_same++;
				$display("same mstr_xtn.HRDATA=%0d | slv_xtn.HRDATA=%0d", mstr_xtn.HRDATA,slv_xtn.HRDATA);
			end
			else
			begin
				rdata_not_same++;
				$display("mismatch mstr_xtn.HRDATA=%0d | slv_xtn.HRDATA=%0d", mstr_xtn.HRDATA,slv_xtn.HRDATA);
			end
		end
	endtask

	function void report_phase(uvm_phase phase);
		$display("********************scoreboard report********************");
		$display("addr_same : %0d | addr_not_same : %0d", addr_same, addr_not_same);
		$display("wdata_same : %0d | wdata_not_same : %0d", wdata_same, wdata_not_same);
		$display("rdata_same : %0d | rdata_not_same : %0d", rdata_same, rdata_not_same);
	endfunction	

endclass
...
          
