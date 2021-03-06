library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pf_data_types.all;
use work.pf_constants.all;

entity pf_ip_wrapper is
      port (
        clk: in std_logic;
        rst: in std_logic;
        start: in std_logic;
        input: in pf_data(N_PF_IP_CORE_IN_CHANS - 1 downto 0);
        done: out std_logic;
        idle: out std_logic;
        ready: out std_logic;
        output : out pf_data(N_PF_IP_CORE_OUT_CHANS - 1 downto 0)
        );
      
end pf_ip_wrapper;

architecture rtl of pf_ip_wrapper is
  
begin

--  pf_algo : entity work.mp7wrapped_pfalgo3_full_0
--  pf_algo : entity work.algo_inputs_layer2_v3_0
   pf_algo : entity work.algo_tau_layer2_v3_0
   port map (
      ap_clk => clk,
      ap_rst => rst,
      ap_start => start, -- ??
      ap_done => done, -- ??
      ap_idle => idle, -- ??
      ap_ready => ready, -- ??
      input_0_V => input(0),
      input_1_V => input(1),
      input_2_V => input(2),
      input_3_V => input(3),
      input_4_V => input(4),
      input_5_V => input(5),
      input_6_V => input(6),
      input_7_V => input(7),
      input_8_V => input(8),
      input_9_V => input(9),
      input_10_V => input(10),
      input_11_V => input(11),
      input_12_V => input(12),
      input_13_V => input(13),
      input_14_V => input(14),
      input_15_V => input(15),
      input_16_V => input(16),
      input_17_V => input(17),
      input_18_V => input(18),
      input_19_V => input(19),
      input_20_V => input(20),
      input_21_V => input(21),
      input_22_V => input(22),
      input_23_V => input(23),
      input_24_V => input(24),
      input_25_V => input(25),
      input_26_V => input(26),
      input_27_V => input(27),
      input_28_V => input(28),
      input_29_V => input(29),
      input_30_V => input(30),
      input_31_V => input(31),
      input_32_V => input(32),
      input_33_V => input(33),
      input_34_V => input(34),
      input_35_V => input(35),
      input_36_V => input(36),
      input_37_V => input(37),
      input_38_V => input(38),
      input_39_V => input(39),
      input_40_V => input(40),
      input_41_V => input(41),
      input_42_V => input(42),
      input_43_V => input(43),
      input_44_V => input(44),
      input_45_V => input(45),
      input_46_V => input(46),
      input_47_V => input(47),
      input_48_V => input(48),
      input_49_V => input(49),
      input_50_V => input(50),
      input_51_V => input(51),
      input_52_V => input(52),
      input_53_V => input(53),
      input_54_V => input(54),
      input_55_V => input(55),
      input_56_V => input(56),
      input_57_V => input(57),
      input_58_V => input(58),
      input_59_V => input(59),
      input_60_V => input(60),
      input_61_V => input(61),
      input_62_V => input(62),
      input_63_V => input(63),
      --input_64_V => input(64),
      --input_65_V => input(65),
      --input_66_V => input(66),
      --input_67_V => input(67),
      --input_68_V => input(68),
      --input_69_V => input(69),
      --input_70_V => input(70),
      --input_71_V => input(71),
      output_0_V => output(0),
      output_1_V => output(1),
      output_2_V => output(2),
      output_3_V => output(3),
      output_4_V => output(4),
      output_5_V => output(5)
      --output_6_V => output(6),
      --output_7_V => output(7),
      --output_8_V => output(8),
      --output_9_V => output(9),
      --output_10_V => output(10),
      --output_11_V => output(11),
      --output_12_V => output(12),
      --output_13_V => output(13),
      --output_14_V => output(14),
      --output_15_V => output(15),
      --output_16_V => output(16),
      --output_17_V => output(17),
      --output_18_V => output(18),
      --output_19_V => output(19),
      --output_20_V => output(20),
      --output_21_V => output(21),
      --output_22_V => output(22),
      --output_23_V => output(23),
      --output_24_V => output(24),
      --output_25_V => output(25),
      --output_26_V => output(26),
      --output_27_V => output(27),
      --output_28_V => output(28),
      --output_29_V => output(29),
      --output_30_V => output(30),
      --output_31_V => output(31),
      --output_32_V => output(32),
      --output_33_V => output(33),
      --output_34_V => output(34),
      --output_35_V => output(35),
      --output_36_V => output(36),
      --output_37_V => output(37),
      --output_38_V => output(38),
      --output_39_V => output(39),
      --output_40_V => output(40),
      --output_41_V => output(41),
      --output_42_V => output(42),
      --output_43_V => output(43),
      --output_44_V => output(44),
      --output_45_V => output(45),
      --output_46_V => output(46),
      --output_47_V => output(47),
      --output_48_V => output(48),
      --output_49_V => output(49),
      --output_50_V => output(50),
      --output_51_V => output(51),
      --output_52_V => output(52),
      --output_53_V => output(53),
      --output_54_V => output(54),
      --output_55_V => output(55),
      --output_56_V => output(56),
      --output_57_V => output(57),
      --output_58_V => output(58),
      --output_59_V => output(59),
      --output_60_V => output(60),
      --output_61_V => output(61),
      --output_62_V => output(62),
      --output_63_V => output(63),
      --output_64_V => output(64),
      --output_65_V => output(65),
      --output_66_V => output(66),
      --output_67_V => output(67),
      --output_68_V => output(68),
      --output_69_V => output(69),
      --output_70_V => output(70),
      --output_71_V => output(71)
      );

end rtl;
              
