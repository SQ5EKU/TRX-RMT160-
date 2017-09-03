' Testowo-przykladowy program do sterowania PLL PMB2306T w nadajniku RMT160 (RX/TX)
' Uklad wymaga wymiany uC na 89C2051 , nalezy wlutowac podstawke oraz dolutowac HT7044B jako uklad resetu
' Wysylane sa identyczne dane jak w ukladzie fabrycznym (bez timeout'u)
' Jedna czestotliwosc pracy: 144.800 MHz simplex , krok PLL: 12.5kHz
' Czestotliwosc pracy: 144.800 MHz  , RX: 144.800 MHz - 26.050 MHz = 118.750 MHz
' http://sq5eku.blogspot.com

$regfile = "89c2051.dat"
$crystal = 12800000                                           ' zegar 12.8 MHz

Dim Tmp As Bit                                                ' odcinanie nadawania po jednej rundzie
Dim C As Byte
Dim A As Byte

' jumper'y:
Jp1 Alias P3.0                                                ' pin 1  , JP1
Jp2 Alias P3.1                                                ' pin 2  , JP2
Jp3 Alias P1.3                                                ' pin 15 , JP3
Jp4 Alias P1.2                                                ' pin 14 , JP4
Jp5 Alias P3.2                                                ' pin 6  , JP5
Jp6 Alias P3.3                                                ' pin 7  , JP6
Jp7 Alias P3.4                                                ' pin 8  , JP7
Jp8 Alias P3.5                                                ' pin 9  , JP8



Ptt Alias P3.7                                                ' pin 11 , PTT H=wylaczone , L=zalaczone
Vco Alias P1.4                                                ' pin 16 , VCO H=RX , L=TX
Rx_tx Alias P1.0                                              ' pin 12 , Rx/Tx H=Tx , L=Rx  (przelaczanie zasilania Rx/Tx)
'
Le Alias P1.5                                                 ' pin 17 PMB2306 pin 3 (LE)
Data Alias P1.6                                               ' pin 18 PMB2306 pin 4 (DATA)
Clk Alias P1.7                                                ' pin 19 PMB2306 pin 5 (CLOCK)

Declare Sub Pmb_rx
Declare Sub Pmb_tx
Declare Sub Pmb_r
Declare Sub Pmb_s
Declare Sub Zegarek1
Declare Sub Zegarek2
Declare Sub Le_pulse

Jp1 = 0
Jp2 = 0
Jp3 = 0
Jp4 = 0
Jp5 = 0
Jp6 = 0
Jp7 = 0
Jp8 = 0

Set Ptt
Set Vco
Tmp = 1
Reset Rx_tx
Reset Le
Reset Data
Reset Clk

Waitms 100
Gosub Pmb_s                                                   ' inicjalizacja PLL po wlaczeniu zasilania
Delay
Gosub Pmb_r

'-------------------------------------------------------------  glowna petla

Do
If Tmp = 0 Then
 If Ptt = 0 Then                                              ' jesli PTT wlaczone idz dalej
  Vco = 0                                                     ' przelacz VCO
  Gosub Pmb_tx
  Waitms 10
  Rx_tx = 1                                                   ' wlacz TX
  Tmp = 1
 End If
End If
If Tmp = 1 Then
 If Ptt = 1 Then
  Vco = 1                                                     ' przelacz VCO
  Gosub Pmb_s
  Delay
  Gosub Pmb_r
  delay
  Gosub Pmb_rx
  Rx_tx = 0                                                   ' wlacz RX
  Tmp = 0
 End If
End If

Loop
End

'-------------------------------------------------------------  koniec glownej petli

Pmb_r:
Restore Dat_r
 For A = 1 To 18
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Pmb_rx:
Restore Dat_rx
 For A = 1 To 16
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Pmb_tx:
Restore Dat_tx
 For A = 1 To 16
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Pmb_s:
Restore Dat_s
 For A = 1 To 16
 Read C
  If C = 1 Then
   Gosub Zegarek1
  Else
   Gosub Zegarek2
  End If
 Next A
 Gosub Le_pulse
Return

Zegarek1:
 Set Data
 nop
 Set Clk
 nop
 Reset Clk
 nop
 Reset Data
Return

Zegarek2:
 Set Clk
 nop
 Reset Clk
 nop
Return

Le_pulse:
 nop
 Set Le
 nop
 Reset Le
 nop
 Reset Data
Return

'_______________________________________________________________________________
' 16 bitowy rejestr N:
Dat_rx:
'
' VCO Rx: 118.750 MHz : 12.5kHz = 9500 (podzial N)
'    |------------------------N--------------------------|   |adr|
Data 1 , 0 , 0 , 1 , 0 , 1 , 0 , 0 , 0 , 1 , 1 , 1 , 0 , 0 , 1 , 0

'_______________________________________________________________________________
' 16 bitowy rejestr N:
Dat_tx:
'
' VCO Tx: 144.800 MHz : 12.5kHz = 11584 (podzial N)
'    |------------------------N--------------------------|   |adr|
Data 1 , 0 , 1 , 1 , 0 , 1 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 1 , 0

'_______________________________________________________________________________
' 18 bitowy rejestr R:
Dat_r:
'
' 12.8MHz : 12.5kHz = 1024 (16 bitow R)
'    |------------------------------R----------------------------|   |adr|
Data 0 , 0 , 0 , 0 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 1 , 1

'_______________________________________________________________________________
' 16 bitowy rejestr STATUS2:
Dat_s:
'
'    |-------------------------S-------------------------|   |adr|
Data 0 , 1 , 1 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 1 , 1 , 1 , 1 , 0 , 1