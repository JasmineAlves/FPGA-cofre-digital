# FPGA-cofre-digital
Projeto de circuitos lógicos sequenciais: *Desenvolvimento de um sistema de cofre digital programável usando lógica sequencial*.

## Objetivo
Projetar e implementar, na **linguagem de descrição de hardware Verilog**, um cofre eletrônico com entrada de senha em switches, saídas visuais e comportamento programado por meio de uma **FSM (Finite State Machine)**.

## Ferramentas
- Placa: **DE10-Lite da terasiC**, com FPGA do modelo **MAX10: 10M50DAF484C7G**.
- [Intel Quartus Prime Lite Edition Design Software Version 23.1 for Windows](https://www.intel.com/content/www/us/en/software-kit/795188/intel-quartus-prime-lite-edition-design-software-version-23-1-for-windows.html).
- Linguagem de descrição de hardware: **Verilog (.v)**.

## Funcionalidades
1. Usuário insere uma sequência de 4 dígitos;
2. O sistema compara com a senha correta programada;
3. Caso a senha esteja correta, o sistema "desbloqueia";
4. Caso a senha esteja incorreta 3 vezes seguidas, o sistema bloqueia por 10 segundos.

### Diagrama da máquina de estados finita
![Diagrama](https://github.com/JasmineAlves/FPGA-cofre-digital/blob/main/Diagrama-FSM.jpeg)

Onde:
- KEY[0] = Botão de confirmação
- KEY[1] = Botão de reset
- SW[3:0] = Teclado para a entrada de digitos
