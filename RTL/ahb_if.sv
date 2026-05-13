# code for ahb_if.sv

  ...
  interface ahb_if(input bit clk); 
	logic HREADY, HRESP, HRESETn, HCLK, HWRITE;
	logic [31:0] HRDATA, HADDR, HWDATA; 
	logic [2:0] HBURST, HSIZE;
	logic [1:0] HTRANS;

	assign HCLK = clk;

	clocking mstr_drv_cb @(posedge clk);
		default input #1 output #1;
		output HRESETn;
		input HRESP;
		input HREADY;
		input HRDATA;
		output HWRITE;
		output HADDR;
		output HWDATA;
		output HBURST;
		output HSIZE;
		output HTRANS;	
	endclocking 

	clocking mstr_mon_cb @(posedge clk);
		default input #1 output #1;
		input HRESP;
		input HREADY;
		input HRDATA;
		input HWRITE;
		input HADDR;
		input HWDATA;
		input HBURST;
		input HSIZE;
		input HTRANS;	
	endclocking 

	clocking slv_drv_cb @(posedge clk);
		default input #1 output #1;
		output HRESP;
		output HREADY;
		output HRDATA;
		input HWRITE;
		input HADDR;
		input HWDATA;
		input HBURST;
		input HSIZE;
		input HTRANS;	
	endclocking 

	clocking slv_mon_cb @(posedge clk);
		default input #1 output #1;
		input HRESP;
		input HREADY;
		input HRDATA;
		input HWRITE;
		input HADDR;
		input HWDATA;
		input HBURST;
		input HSIZE;
		input HTRANS;	
	endclocking


	modport MSTR_DRV_MP(clocking mstr_drv_cb);
	modport MSTR_MON_MP(clocking mstr_mon_cb);
	modport SLV_DRV_MP(clocking slv_drv_cb);
	modport SLV_MON_MP(clocking slv_mon_cb);

endinterface	

    ...


