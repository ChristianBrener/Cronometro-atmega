.def AUX = R16
.def CTRL = R17
.def ALT = R21
.def LIMIT = R22
.def S = R23
.def M = R24
.def H = R25
.equ LCD_RS = PD1
.equ LCD_E = PD0
.equ B1 = PD2
.equ B2	= PD3

.ORG 0x00	
RJMP start 

.ORG 0x02	;endereço da interrupcão externa do INT0
RJMP inter1
.ORG 0x04	;endereço da interrupcão externa do INT1
RJMP inter2

;inicializacão
start:

;Configurando as Portas
LDI AUX, 0xFF ;Todas as Portas de dados do LCD como entrada
OUT DDRB, AUX
LDI AUX, 0x03 ;Portas do E, RS como entrada
OUT DDRD, AUX
LDI AUX, 0x0C ;Definindo os 2 botões
OUT	PORTD, AUX

;Configuracão das interrupcões externas
LDI AUX, 0x0A	;Os dois botões com interrupcão de borda de decida
STS EICRA, AUX										
LDI AUX, 0x03 	;habilita as interrupcões INT0 e INT1			
OUT EIMSK, AUX
SEI ;Ativa interrupcão global

;Colocando o Tempo inicial
LDI S, 00 ;Segundos
LDI M, 00 ;Minutos
LDI H, 00 ;Horas

;Configuração do LCD
LDI AUX, 0x30;Configuração: interface 8 bit ,font 5 x 7 , 1 linha
RCALL lcd_command; Enviar a Configuração para o comando
LDI AUX, 0x0C;Configuração: display ligado, mostrar cursor, cursor não pisca
RCALL lcd_command; Enviar a Configuração para o comando

;Rotina Principal
main:
LDI AUX, 0x01 ;Limpar display
RCALL lcd_command

CPI ALT, 1	;Compara se alt é igual 1, 
BREQ decr_timer;se for igual decrementa o tempo
PUSH CTRL	;Salva valor para ser usado futuramente
PUSH ALT	;//
RCALL timer ;Incrementar
RCALL lcd_print ;imprimir no lcd
POP ALT	;Retorna o valor salvo anteriormente
POP CTRL;//

RCALL delay
RJMP main

decr_timer:
LDI AUX, 0x01 ;Limpar display
RCALL lcd_command

CPI ALT, 0	;Compara se alt é igual 0, 
BREQ main	;se for igual incrementa o tempo
PUSH CTRL	;Salva valor para ser usado futuramente
PUSH ALT	;//
RCALL timer_dec ;Decrementa
RCALL lcd_print ;imprimir no lcd
POP ALT	;Retorna o valor salvo anteriormente
POP CTRL;//

RCALL delay
RJMP decr_timer

;Tratamento de interrupcões
inter1:	;interrupcão botão 1
RCALL delay_1ms	 ;delay para evitar ruido
CPI ALT, 1	;Compara se o valor ja foi modificado uma vez
BREQ inter_cp1;Se foi modificado vá para inter_cp1
LDI ALT, 1	;Se não, coloque o valor em 1
RETI	;Retorne e saia da interrupcão

inter_cp1:
LDI ALT, 0 ;Zerar o valor de alt
RETI;Sair da interrupcão

inter2:	;interrupcão botão 2
RCALL delay_1ms ;delay para evitar ruido
CPI CTRL, 1	 ;Compara se o valor ja foi modificado uma vez
BREQ inter_cp2;Se foi modificado vá para inter_cp1
LDI CTRL, 1	 ;Se não, coloque o valor em 1
RETI	;Retorne e saia da interrupcão

inter_cp2:
LDI CTRL, 0 ;Zerar o valor de alt
RETI ;Sair da interrupcão

timer:

LDI LIMIT, 60 ;Define o limite para 60s
INC S ; Faz o incremento dos segundos
CP S, LIMIT ; compara para ver se atingiu o limite
BREQ timer_M ; se LIMIT e S for igual vai para timer_M, se não retorna

RET

;contador minutos
timer_M:
LDI S, 0 ;Zera os segundos
LDI LIMIT, 60; Define o limite para 60m
INC M; faz o incremento
CP M, LIMIT ; ver se os minutos atingiu o limite
BREQ timer_H ; se atingiu o limite vai para timer_H, se não retorna
RET

;contador horas
timer_H:
LDI M, 0 ;Zera os minutos
LDI LIMIT, 24; Define o limite para 24h
INC H; faz o incremento
CP H, LIMIT ; ver se as horas atingiu o limite
BREQ zero_H ; se atingiu o limite vai para zero_H, se não
RET; Retorna

;Zera as horas
zero_H:
LDI H, 0
RET

;tempo decrementado
timer_dec:
LDI LIMIT, 0 ;Define o limite para 0s
DEC S ; Faz o decremento
CP S, LIMIT ; compara para ver se atingiu o limite
BRMI timer_m_dec ; se S for menor que LIMIT vai para timer_M, se não retorna
RET

;contador minutos
timer_m_dec:
LDI S, 59 ;Zera os segundos
LDI LIMIT, 0; Define o limite para 0m
DEC M; faz o Decremento
CP M, LIMIT ; compara o tempo com o LIMIT
BRMI timer_h_dec ; se M for menor atingiu o limite vai para timer_H, se não retorna
RET

;contador horas
timer_h_dec:
LDI M, 59 ;Zera os minutos
LDI LIMIT, 0; Define o limite para 0h
DEC H; faz o decremento
CP H, LIMIT ; compara o tempo com o LIMIT
BRMI turn_h ; se atingiu o limite vai para zero_H, se não
RET; Retorna

;coloca 23h quando passa do limite
turn_h:
LDI H, 23
RET

;Mostrar o tempo
lcd_print:
CPI CTRL, 1	;Compara se alt é igual 1, 
BREQ print_ms;se for igual mostra minutos e segundos


;mostrar horas
CLR CTRL ;Limpa o registrador
MOV AUX, H ; coloca o valor dos segundos em AUX
RCALL sub_timer ;chama a rotina de separacão
MOV ALT, AUX ;Armazena o valor de resultado AUX em ALT
MOV AUX, CTRL; Armazena o valor de resultado CTRL em AUX
RCALL send_n_ascii ;Mostra AUX convertido em ascii
MOV AUX, ALT;Retorna o valor anterior do AUX
RCALL send_n_ascii; Mostra o valor do aux
LDI AUX, ':'; Mostrar (:)
RCALL lcd_Data;

;mostrar minutos
CLR CTRL
MOV AUX, M ; colocar o valor dos segundos em AUX
RCALL sub_timer ;chama a rotina de separacão
MOV ALT, AUX ;Armazena o valor de resultado AUX em ALT
MOV AUX, CTRL; Armazena o valor de resultado CTRL em AUX
RCALL send_n_ascii ;Mostra AUX convertido em ascii
MOV AUX, ALT; Armazena o valor anterior do AUX
RCALL send_n_ascii; Mostra o valor do aux
RET; Se estiver retorna

print_ms:
LDI AUX, 0x01 ;Limpar display
RCALL lcd_command
;mostrar minutos
CLR CTRL
MOV AUX, M ; colocar o valor dos segundos em AUX
RCALL sub_timer ;chama a rotina de separacão
MOV ALT, AUX ;Armazena o valor de resultado AUX em ALT
MOV AUX, CTRL; Armazena o valor de resultado CTRL em AUX
RCALL send_n_ascii ;Mostra AUX convertido em ascii
MOV AUX, ALT; Armazena o valor anterior do AUX
RCALL send_n_ascii; Mostra o valor do aux

;mostrar segundos
CLR CTRL ;Limpar Ctrl
LDI AUX, ':'
RCALL lcd_Data
MOV AUX, S ; coloca o valor dos segundos em AUX
RCALL sub_timer ;chama a rotina de separacão
MOV ALT, AUX ;Armazena o valor de resultado AUX em ALT
MOV AUX, CTRL; Armazena o valor de resultado CTRL em AUX
RCALL send_n_ascii ;Mostra AUX convertido em ascii
MOV AUX, ALT; Retorna o valor anterior do AUX
RCALL send_n_ascii; Mostra o valor do aux
RET

;Rotina que separa os numeros com mais de 2 digitos
sub_timer:
LDI ALT, 10 ;armazena 10 em alt
CPI AUX, 10 ;Compara se o tempo é igual ou maior que 10
BRSH sub_timer_high ;se for vai para rotina sub_timer_high, se não
RET; retorna

;Rotina para pegar o resto e a divisao
sub_timer_high:
SBC AUX, ALT ;diminui 10 de AUX
INC CTRL ; Incremento do ctrl
RJMP sub_timer

;Converter numeros para a tabela ASCII
send_n_ascii:
LDI CTRL, 0x30 ;Armazena valor onde começa os numeros na table asci
ADD AUX, CTRL; ; adiciona os numeros na tabela ascii
RCALL lcd_Data ;Envia dados
RET

;gravar dados no LCD (RS = 1, E = 1)
lcd_Data:
SBI PortD, LCD_RS ; definir RS para selecionar o registro de dados
SBI PortD, LCD_E ; definir E
OUT PortB, AUX; ;colocar dados
RCALL delay_1ms
CBI PortD, LCD_E; desmarque E
CBI PortD, LCD_RS; e RS
RET; Retorna da sub-rotina

;escreve os comandos no LCD (RS = 0, E = 1)
lcd_command:
CBI PortD, LCD_RS ;Limpa RS
SBI PortD, LCD_E ;definir E
OUT PortB, AUX ;Colocar dados
RCALL delay_1ms
CBI PortD, LCD_E ;limpar E
RET ;retorno

delay_1ms:
PUSH R18
PUSH R19
ldi r18, 2
ldi r19, 9
L1: dec r19
brne L1
dec r18
brne L1
POP R19
POP R18
RET

delay:
PUSH R18
PUSH R19
ldi r18, 6
ldi r19, 9
ldi r20, 74
L2: dec r20
brne L2
dec r19
brne L2
dec r18
brne L2
POP R19
POP R18
RET