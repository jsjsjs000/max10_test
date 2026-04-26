set_global_assignment -entity "soft_lvds_ip" -library "lib_soft_lvds_ip" -name IP_TOOL_NAME "altera_soft_lvds"
set_global_assignment -entity "soft_lvds_ip" -library "lib_soft_lvds_ip" -name IP_TOOL_VERSION "25.1"
set_global_assignment -entity "soft_lvds_ip" -library "lib_soft_lvds_ip" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_soft_lvds_ip" -name SPD_FILE [file join $::quartus(sip_path) "soft_lvds_ip.spd"]

set_global_assignment -library "lib_soft_lvds_ip" -name MISC_FILE [file join $::quartus(sip_path) "soft_lvds_ip_sim/soft_lvds_ip.v"]
set_global_assignment -library "lib_soft_lvds_ip" -name MISC_FILE [file join $::quartus(sip_path) "soft_lvds_ip_sim/altera_soft_lvds/altera_soft_lvds_tx_ERzqh.v"]
