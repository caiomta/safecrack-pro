# SafeCrack Pro - Cofre Digital em FPGA

- **Disciplina:** CIN0130 - Sistemas Digitais
- **Professor:** Victor Medeiros
- **Equipe Desenvolvedora:**
  - **Caio Tenório** (*[GitHub](https://github.com/caiomta)* | *[LinkedIn](https://www.linkedin.com/in/caiomta)*)
  - **José Vinícius Albino** (*[GitHub](https://github.com/jva2-cyber)*)
  - **Lucas de Oliveira** (*[GitHub](https://github.com/0guruzet)*)
  - **Natália Bourbon** (*[GitHub](https://github.com/nataliabourbon)*)

## Visão Geral

O **SafeCrack Pro** é um sistema de cofre digital interativo desenvolvido em SystemVerilog e sintetizado na placa de desenvolvimento **Terasic DE2-115** (equipada com o FPGA **Altera Cyclone IV E EP4CE115F29**).

### Interface do Usuário

A interação com o cofre ocorre através dos botões de pressão, dos displays de 7 segmentos e dos barramentos de LEDs da placa:

#### Botões de Controle (`KEY[3:0]`)

- **`KEY[3]` (Decremento):** Decrementa o valor do dígito ativo, contando com *wrap-around* (após o 0 vai para 9);
- **`KEY[2]` (Incremento):** Incrementa o valor do dígito ativo, contando com *wrap-around* (após o 9 vai para 0);
- **`KEY[1]` (Confirmação):** Fixa o valor ajustado para o dígito ativo e avança para o dígito seguinte. Após o 4° dígito, inicia a validação (ou persistência, em caso de modo edição). Caso seja pressionado durante o estado desbloqueado, o sistema entra em modo de edição de senha;
- **`KEY[0]` (Reset):** Aciona o reset assíncrono (`rstn`), retornando para o estado inicial do sistema (mas sem resetar a senha persistida na memória, se alterada).
  
#### Displays de 7 Segmentos (`HEX[4:0]`)

- **`HEX[3:0]` (Senha Digitada):** Exibem os 4 dígitos da senha, da esquerda para a direita, sendo `HEX[3]` o primeiro dígito. O display correspondente à posição ativa é alterada em tempo real durante o ajuste. Após confirmar o último dígito ou usar o reset assíncrono, todos os dígitos são zerados;
- **`HEX[4]` (Dígito Ativo):** Exibe o índice do dígito que está atualmente em edição (iniciando em 1 e terminando em 4).

#### LEDs Vermelhos e Verdes:

- **Apenas Vermelhos Acesos:** Acontece por 3 segundos após a combinação inserida não bater com a senha definida em memória, indicando falha no acesso;
- **Apenas Verdes Acesos:** Acontece por 5 segundos após a combinação inserida bater com a senha definida em memória, indicando acesso bem-sucedido;
- **Vermelhos e Verdes Acesos:** Acontece para indicar que o sistema está em modo de edição da senha.

### Gerenciamento de Senha

- **Senha Padrão:** Ao iniciar o programa na placa, o cofre é inicializado automaticamente com a senha padrão `0000`;
- **Edição de Senha:** Ao pressionar o botão de confirmação enquanto o sistema está em estado desbloqueado, é possível inserir uma nova senha que será utilizada nas validações após a confirmação da edição. Se ocorrer reset durante o processo de edição, a senha anterior mantém-se.
- **Reset:** O reset assíncrono não redefine a senha para a padrão após alterada.

## Máquina de Estados Finita (FSM)

```mermaid
stateDiagram-v2
    [*] --> EDIT1 : !rstn

    EDIT1 --> EDIT2 : confirm_pulse
    EDIT2 --> EDIT3 : confirm_pulse
    EDIT3 --> EDIT4 : confirm_pulse
    EDIT4 --> VALIDATE : confirm_pulse
    
    state VALIDATE <<choice>>
    VALIDATE --> UNLOCKED : match_pass
    VALIDATE --> INCORRECT : !match_pass

    UNLOCKED --> EDIT1 : timer_done (5s)
    INCORRECT --> EDIT1 : timer_done (3s)

    UNLOCKED --> NEW_PASS1 : confirm_pulse 
    NEW_PASS1 --> NEW_PASS2 : confirm_pulse 
    NEW_PASS2 --> NEW_PASS3 : confirm_pulse 
    NEW_PASS3 --> NEW_PASS4 : confirm_pulse 
    NEW_PASS4 --> SAVE_PASS : confirm_pulse

    SAVE_PASS --> EDIT1
```

> [!WARNING]
> Se o diagrama não estiver sendo rendenizado pelo seu leitor de Markdown, *[clique aqui para acessar o diagrama em PNG](./state-diagram.png)*.

### Descrição dos Estados

- **`EDIT1` a `EDIT4` (Digitação da Senha):** Estados de inserção dos 4 dígitos da senha para tentativa de acesso. Cada estado atribui o índice ativo a `selected_digit` (que vai de `2'd0` a `2'd3` e é convertido pelo driver do display para 1-4). A cada `confirm_pulse`, a FSM gera o pulso `save_digit` para registrar o dígito atual e avança para a posição seguinte. Ao confirmar o 4° dígito, avança para `VALIDATE`;
- **`VALIDATE` (Validação do Acesso):** Estado combinacional de tomada de decisão. Se a combinação digitada bater com a senha armazenada em memória (`match_pass == 1`), avança para `UNLOCKED`. Caso contrário (`match_pass == 0`), avança para `INCORRECT`;
- **`UNLOCKED` (Cofre Desbloqueado):** Ativa `unlocked`, zerando o display da senha inserida, retornando o índice `selected_digit` para `2'd0`, acionando os LEDs verdes e ativando o temporizador de 5s. Se o botão de confirmação for pressionado, gerando `confirm_pulse`, a FSM redireciona para o modo de edição de senha (`NEW_PASS1`). Caso contrário, ao esgotar do temporizador (`timer_done`), o sistema retorna para `EDIT1`. 
- **`INCORRECT` (Senha Incorreta):** Ativa `incorrect`, zerando o display da senha inserida, retornando o índice `selected_digit` para `2'd0`, acionando os LEDs vermelhos e ativando o temporizador de 3s. Ao término do temporizador (`timer_done`), o sistema retorna para `EDIT1`.
- **`NEW_PASS1` a `NEW_PASS4` (Edição de Senha):** Estados para digitação da nova combinação de 4 dígitos. Mantém o sinal `edit_mode` ativo, o que liga os LEDs verdes e vermelhos, sinalizando o modo de edição. A cada confirmação, armazena o dígito com o pulso `save_digit`. Após confirmar o 4° dígito, avança para `SAVE_PASS`.
- **`SAVE_PASS` (Persistência da Nova Senha):** Ativa simultaneamente `edit_mode` e `save_pass`, zerando o display da senha inserida, retornando o índice `selected_digit` para `2'd0` e sinalizando ao `password_manager` para sobrescrever a senha gravada na memória com a nova combinação. Imediatamente após, transiciona para `EDIT1`.

> [!NOTE]
> Ao aplicar o reset assícrono (`!rstn`) em qualquer estado, o programa retorna para `EDIT1`.

## Módulos
