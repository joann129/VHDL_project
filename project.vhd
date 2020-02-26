LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_signed.all ;
--USE work.subccts.all ;

ENTITY project IS
	PORT (	state		: out		std_logic_vector(1 downto 0);	--LEDG 1 DOWNTO 0
			Data 		: IN 		STD_LOGIC_VECTOR(2 DOWNTO 0) ;	--SW 2 DOWNTO 0
			Reset, w 	: IN 		STD_LOGIC ;	--KEY0 SW17
			Clock 		: IN 		STD_LOGIC ;	--KEY1
			F, Rx, Ry 	: IN 		STD_LOGIC_VECTOR(2 DOWNTO 0) ; --SW 11 DOWNTO 3
			Done 		: BUFFER 	STD_LOGIC ;	--LEDR 17
			BusWires 	: INOUT 	STD_LOGIC_VECTOR(2 DOWNTO 0) ) ; --LEDR 2 DOWNTO 0
END project ;

ARCHITECTURE Behavior OF project IS
	SIGNAL Rin, Rout, X, Y : STD_LOGIC_VECTOR(0 TO 7) ;
	SIGNAL Clear, High : STD_LOGIC ;
	signal AddSub : std_logic_vector(1 downto 0);
	SIGNAL Extern, Ain, Gin, Gout, FRin, tempin, tempout : STD_LOGIC ;
	SIGNAL  I : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
	signal T,Count	:	std_logic_vector(1 downto 0);
	SIGNAL R0, R1, R2, R3 ,R4,R5,R6,R7: STD_LOGIC_VECTOR(2 DOWNTO 0) ;
	SIGNAL A, Sum, G, temp : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
	SIGNAL Func, FuncReg : STD_LOGIC_VECTOR(1 TO 9) ;
	SIGNAL Sel : STD_LOGIC_VECTOR(1 TO 11) ;
	
		COMPONENT regn
		GENERIC (n : INTEGER := 3);
		PORT ( R : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
			   Rin, Clock : IN STD_LOGIC;
			   Q : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	END COMPONENT;
	COMPONENT upcount
		PORT (	Reset, Clear, Clock	: IN	 		STD_LOGIC ;
			Q 			: BUFFER 	STD_LOGIC_VECTOR(1 DOWNTO 0) ) ;
	END COMPONENT;
	COMPONENT dec3to8
		PORT ( w : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
	En : IN STD_LOGIC;
	y : OUT STD_LOGIC_VECTOR(0 TO 7));
	END COMPONENT;
	
BEGIN
	 High <= '1' ;
	Clear <= Done OR (NOT w AND NOT T(1) AND not T(0)) ;
	counter: upcount PORT MAP (	Reset, Clear, Clock, Count ) ;
	T <= Count;
	state <= T;
	Func <= F & Rx & Ry ;
	FRin <= w AND NOT T(1) AND NOT T(0)  ;
	functionreg: regn GENERIC MAP ( N => 9 ) 
		PORT MAP ( Func, FRin, Clock, FuncReg ) ;
	I <= FuncReg(1 To 3);
	decX: dec3to8 PORT MAP ( FuncReg(4 TO 6), High, X ) ;
	decY: dec3to8 PORT MAP ( FuncReg(7 TO 9), High, Y ) ;

	controlsignals: PROCESS (T, I, X, Y)
	BEGIN
		Extern <= '0' ; Done <= '0' ; Ain <= '0' ; Gin <= '0';
		Gout <= '0' ; AddSub <= "00" ; Rin <= "00000000" ; Rout <= "00000000" ; tempin <= '0'; tempout <= '0';
		CASE T IS
				WHEN "00" => 
				WHEN "01" =>
						CASE I IS
								WHEN "001" =>	--load
										Extern <= '1' ; Rin <= X; Done <='1';
								WHEN "000" =>	--move
										Rout <= Y ; Rin <= X; Done <='1';
								when "110" =>	--mvnz
										case G is
												when "000" =>
												when others =>
													Rout <= Y ; Rin <= X; Done <='1';
										end case;
								when "100" =>	--swap
										Rout <= X ; tempin <= '1';
								WHEN OTHERS =>
										Rout <= X ; Ain <= '1';
						END CASE;
				WHEN "10" =>
						CASE I IS
								WHEN "010" =>	--add
										Rout <= Y ; Gin <= '1'; AddSub <= "00";
								WHEN "011" =>	--sub
										Rout <= Y ; AddSub <= "01" ; Gin <= '1';
								when "101" =>	--inc
										AddSub <= "10"; Gin <= '1';
								when "111" =>	--xor
										Rout <= Y ; AddSub <= "11"; Gin <= '1';
								when "100" =>	--swap
										Rout <= Y; Rin <= X;
								WHEN OTHERS =>
						END CASE;
				WHEN OTHERS =>
						CASE I IS
								WHEN "000" =>
								WHEN "001" =>
								when "100" =>	--swap
										tempout <= '1'; Rin <= Y; Done <= '1';
								when "110" =>
								WHEN OTHERS =>
										Gout <= '1' ; Rin <= X ; Done <= '1' ;
						END CASE;
				END CASE;
	END PROCESS;
reg0: regn PORT MAP ( BusWires, Reset, Rin(0), Clock, R0 ) ;
reg1: regn PORT MAP ( BusWires, Reset, Rin(1), Clock, R1 ) ;
reg2: regn PORT MAP ( BusWires, Reset, Rin(2), Clock, R2 ) ;
reg3: regn PORT MAP ( BusWires, Reset, Rin(3), Clock, R3 ) ;
reg4: regn PORT MAP ( BusWires, Reset, Rin(4), Clock, R4 ) ;
reg5: regn PORT MAP ( BusWires, Reset, Rin(5), Clock, R5 ) ;
reg6: regn PORT MAP ( BusWires, Reset, Rin(6), Clock, R6 ) ;
reg7: regn PORT MAP ( BusWires, Reset, Rin(7), Clock, R7 ) ;
regA: regn PORT MAP ( BusWires, Reset, Ain, Clock, A ) ;
regT: regn PORT MAP ( BusWires, Reset, tempin, Clock, temp ) ;
alu:
	WITH AddSub SELECT
		Sum <= 	A + BusWires WHEN "00",
				A - BusWires WHEN "01",
				A + 1 when "10",
				A xor BusWires when others;
	regG: regn PORT MAP ( Sum, Reset, Gin, Clock, G ) ;
	Sel <= Rout & Gout & tempout & Extern;
	WITH Sel SELECT
		BusWires <= R0	WHEN "10000000000",
					R1	WHEN "01000000000",
					R2	WHEN "00100000000",
					R3	WHEN "00010000000",
					R4	WHEN "00001000000",
					R5	WHEN "00000100000",
					R6	WHEN "00000010000",
					R7	WHEN "00000001000",
					G	WHEN "00000000100",
					temp WHEN "00000000010",
					Data when others;
END Behavior ;