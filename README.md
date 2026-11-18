# SafeCrack Pro - Cofre Digital em FPGA

- **Disciplina:** CIN0130 - Sistemas Digitais
- **Professor:** Victor Medeiros

### Equipe Desenvolvedora

- **Caio Tenório** ([GitHub](https://github.com/caiomta) | [LinkedIn](https://www.linkedin.com/in/caiomta))
- **José Vinícius Albino** ([GitHub](https://github.com/jva2-cyber))
- **Lucas de Oliveira** ([GitHub](https://github.com/nataliabourbon))
- **Natália Bourbon** ([GitHub](https://github.com/0guruzet))

## Módulos

### Button Debouncer

O módulo **`btn_debouncer`** é responsável por sanitizar os sinais assíncronos vindos dos botões mecânicos da placa DE2-115 (`KEY`). Ele elimina o ruído mecânico (*bouncing*), evita problemas de metaestabilidade no domínio de clock do FPGA e garante a geração de um **pulso único de exatamente 1 ciclo de clock** por clique.

#### Parâmetros Genéricos

* **`CLK_FREQ`** (Padrão: `50_000_000` Hz): Frequência do clock de entrada. Na simulação, este parâmetro pode ser reduzido (ex.: `100`) para acelerar os testes.
* **`DEB_MS`** (Padrão: `20` ms): Tempo mínimo de estabilização exigido para validar o clique.

#### Funcionalidades e Implementação

- **Sincronização de 2 Estágios (Anti-metaestabilidade):** Utiliza dois flip-flops em cascata (`btn_sync0` e `btn_sync1`) para capturar o sinal assíncrono do botão e alinhá-lo com a borda de subida do clock (`clk`), prevenindo estados metaestáveis no sistema;
- **Adequação de Polaridade (`btn_active`):** Como os botões da DE2-115 são *active-low* (pressionado = `0`), o sinal sincronizado é invertido (`assign btn_active = !btn_sync1`), fazendo com que `1` represente o estado pressionado;
- **Filtragem de Ruído por Contagem (`deb_cnt`):** O sinal só é considerado estável se mantiver o novo nível lógico de forma ininterrupta por `DEB_CYCLES` (calculado a partir de `DEB_MS`). Qualquer oscilação mecânica no meio do processo reinicia a contagem (`deb_cnt <= '0`), garantindo que ruídos não sejam registrados como cliques válidos;
- **Detecção de Borda de Subida (`btn_pulse`):** Através da comparação entre o estado estável atual (`btn_stable`) e o estado no ciclo imediatamente anterior (`btn_prev`), a lógica combinacional `assign btn_pulse = btn_stable & !btn_prev` gera um único pulso com duração de 1 ciclo de clock. Isso impede que manter o botão pressionado gere múltiplos acionamentos indesejados.

#### Interface do Módulo (E/S)

| Porta | Tipo | Largura | Descrição |
| :--- | :--- | :--- | :--- |
| `clk` | Entrada | 1 bit | Clock principal do sistema (50 MHz na placa) |
| `rstn` | Entrada | 1 bit | Reset assíncrono ativo em nível baixo |
| `btn` | Entrada | 1 bit | Entrada bruta do botão mecânico (ativo em `0`) |
| `btn_pulse` | Saída | 1 bit | Pulso limpo de 1 ciclo indicando a confirmação do clique |

### Display Driver

### Input Handler

### Led Controller

### Password Manager

### Timer Counter