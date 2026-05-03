	component nios_ii_e is
		port (
			clk_clk : in std_logic := 'X'  -- clk
		);
	end component nios_ii_e;

	u0 : component nios_ii_e
		port map (
			clk_clk => CONNECTED_TO_clk_clk  -- clk.clk
		);

