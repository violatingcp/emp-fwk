library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.emp_data_types.all;
use work.pf_constants.all;

entity sort_ip_wrapper is
      port (
        clk: in std_logic;
        rst: in std_logic;
        start: in std_logic;
        input: in ldata(N_PF_IP_CORE_IN_CHANS - 1 downto 0);
        done: out std_logic;
        idle: out std_logic;
        ready: out std_logic;
        output : out ldata(N_PF_IP_CORE_OUT_CHANS - 1 downto 0)
        );
      
end sort_ip_wrapper;

architecture rtl of sort_ip_wrapper is
  
begin

   pf_algo : entity work.algo_sort_v5_0
   port map (
      ap_clk => clk,
      ap_rst => rst,
      ap_start => start, -- ??
      ap_done => done, -- ??
      ap_idle => idle, -- ??
      ap_ready => ready, -- ??
      input_0_V => input(0).data,
      input_1_V => input(1).data,
      input_2_V => input(2).data,
      input_3_V => input(3).data,
      input_4_V => input(4).data,
      input_5_V => input(5).data,
      input_6_V => input(6).data,
      input_7_V => input(7).data,
      input_8_V => input(8).data,
      input_9_V => input(9).data,
      input_10_V => input(10).data,
      input_11_V => input(11).data,
      input_12_V => input(12).data,
      input_13_V => input(13).data,
      input_14_V => input(14).data,
      input_15_V => input(15).data,
      input_16_V => input(16).data,
      input_17_V => input(17).data,
      input_18_V => input(18).data,
      input_19_V => input(19).data,
      input_20_V => input(20).data,
      input_21_V => input(21).data,
      input_22_V => input(22).data,
      input_23_V => input(23).data,
      input_24_V => input(24).data,
      input_25_V => input(25).data,
      input_26_V => input(26).data,
      input_27_V => input(27).data,
      input_28_V => input(28).data,
      input_29_V => input(29).data,
      input_30_V => input(30).data,
      input_31_V => input(31).data,
      input_32_V => input(32).data,
      input_33_V => input(33).data,
      input_34_V => input(34).data,
      input_35_V => input(35).data,
      --input_36_V => input(36).data,
      --input_37_V => input(37).data,
      --input_38_V => input(38).data,
      --input_39_V => input(39).data,
      --input_40_V => input(40).data,
      --input_41_V => input(41).data,
      --input_42_V => input(42).data,
      --input_43_V => input(43).data,
      --input_44_V => input(44).data,
      --input_45_V => input(45).data,
      --input_46_V => input(46).data,
      --input_47_V => input(47).data,
      --input_48_V => input(48).data,
      --input_49_V => input(49).data,
      --input_50_V => input(50).data,
      --input_51_V => input(51).data,
      --input_52_V => input(52).data,
      --input_53_V => input(53).data,
      --input_54_V => input(54).data,
      --input_55_V => input(55).data,
      --input_56_V => input(56).data,
      --input_57_V => input(57).data,
      --input_58_V => input(58).data,
      --input_59_V => input(59).data,
      --input_60_V => input(60).data,
      --input_61_V => input(61).data,
      --input_62_V => input(62).data,
      --input_63_V => input(63).data,
      --input_64_V => input(64).data,
      --input_65_V => input(65).data,
      --input_66_V => input(66).data,
      --input_67_V => input(67).data,
      --input_68_V => input(68).data,
      --input_69_V => input(69).data,
      --input_70_V => input(70).data,
      --input_71_V => input(71).data,
      output_0_V => output(0).data,
      output_1_V => output(1).data,
      output_2_V => output(2).data,
      output_3_V => output(3).data,
      output_4_V => output(4).data
      --output_5_V => output(5).data,
      --output_6_V => output(6).data,
      --output_7_V => output(7).data,
      --output_8_V => output(8).data,
      --output_9_V => output(9).data,
      --output_10_V => output(10).data,
      --output_11_V => output(11).data,
      --output_12_V => output(12).data,
      --output_13_V => output(13).data,
      --output_14_V => output(14).data,
      --output_15_V => output(15).data,
      --output_16_V => output(16).data,
      --output_17_V => output(17).data,
      --output_18_V => output(18).data,
      --output_19_V => output(19).data,
      --output_20_V => output(20).data,
      --output_21_V => output(21).data,
      --output_22_V => output(22).data,
      --output_23_V => output(23).data,
      --output_24_V => output(24).data,
      --output_25_V => output(25).data,
      --output_26_V => output(26).data,
      --output_27_V => output(27).data,
      --output_28_V => output(28).data,
      --output_29_V => output(29).data,
      --output_30_V => output(30).data,
      --output_31_V => output(31).data,
      --output_32_V => output(32).data,
      --output_33_V => output(33).data,
      --output_34_V => output(34).data,
      --output_35_V => output(35).data,
      --output_36_V => output(36).data,
      --output_37_V => output(37).data,
      --output_38_V => output(38).data,
      --output_39_V => output(39).data,
      --output_40_V => output(40).data,
      --output_41_V => output(41).data,
      --output_42_V => output(42).data,
      --output_43_V => output(43).data,
      --output_44_V => output(44).data,
      --output_45_V => output(45).data,
      --output_46_V => output(46).data,
      --output_47_V => output(47).data,
      --output_48_V => output(48).data,
      --output_49_V => output(49).data,
      --output_50_V => output(50).data,
      --output_51_V => output(51).data,
      --output_52_V => output(52).data,
      --output_53_V => output(53).data,
      --output_54_V => output(54).data,
      --output_55_V => output(55).data,
      --output_56_V => output(56).data,
      --output_57_V => output(57).data,
      --output_58_V => output(58).data,
      --output_59_V => output(59).data,
      --output_60_V => output(60).data,
      --output_61_V => output(61).data,
      --output_62_V => output(62).data,
      --output_63_V => output(63.data,
--      output_64_V => output(64).data,
--      output_65_V => output(65).data,
--      output_66_V => output(66).data,
--      output_67_V => output(67).data,
--      output_68_V => output(68).data,
--      output_69_V => output(69).data,
--      output_70_V => output(70).data,
--      output_71_V => output(71).data
      );

end rtl;
              
