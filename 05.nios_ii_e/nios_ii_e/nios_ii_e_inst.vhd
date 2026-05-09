	component nios_ii_e is
		port (
			clk_clk        : in  std_logic                    := 'X';             -- clk
			inputs_export  : in  std_logic_vector(7 downto 0) := (others => 'X'); -- export
			outputs_export : out std_logic_vector(7 downto 0);                    -- export
			reset_reset_n  : in  std_logic                    := 'X'              -- reset_n
		);
	end component nios_ii_e;

	u0 : component nios_ii_e
		port map (
			clk_clk        => CONNECTED_TO_clk_clk,        --     clk.clk
			inputs_export  => CONNECTED_TO_inputs_export,  --  inputs.export
			outputs_export => CONNECTED_TO_outputs_export, -- outputs.export
			reset_reset_n  => CONNECTED_TO_reset_reset_n   --   reset.reset_n
		);

