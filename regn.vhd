LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY regn IS
GENERIC (n : INTEGER := 3);
PORT ( R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	   Reset : in std_logic;
	   Rin, Clock : IN STD_LOGIC;
	   Q : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regn;
ARCHITECTURE Behavior OF regn IS
BEGIN
	PROCESS (Clock)
	BEGIN
		if(Reset = '0' ) then
			Q <= "000";
		elsif Clock'EVENT AND Clock = '0' then
			IF Rin = '1' THEN
				Q <= R;
			END IF;
		end if;
	END PROCESS;
END Behavior;