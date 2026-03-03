# DMA – Controle de ADC via DMA no dsPIC33

Este repositório contém um exemplo de programa em **Assembly/C para PIC24/dsPIC33** que demonstra o uso de **DMA (Direct Memory Access)** para leitura de múltiplos conversores A/D (ADCs) e transferência automática de dados para buffers em memória.

O código principal está em `main.asm` e configura periféricos como DMA, UART, ADCs, Timers e I/O para trabalhar de forma integrada.

---

## 📌 Visão Geral

O projeto implementa as seguintes funcionalidades:

* Uso de **DMA em modo ping-pong** para capturar amostras de dois canais ADC com buffers duplos;
* Configuração de dois módulos ADC (ADC1 e ADC2) para scan de entradas analógicas;
* Transferência automática de amostras sem intervenção da CPU;
* Interrupções do DMA para processamento/indicação via LEDs;
* Comunicação UART simples para sinalização de fim de aquisição.

---

## 🛠️ Funcionalidades do Sistema

### 📟 Configuração de Periféricos

#### ADC

O ADC1 lê a entrada AN0 e o ADC2 lê AN1, ambos com resolução de 10 bits e modo scan configurado.

#### DMA

Dois canais DMA são configurados (DMA0 e DMA1) para transferir dados diretamente dos buffers ADC para memórias alinhadas com suporte a buffers A/B para ping-pong.

#### Timer

**Timer3** e **Timer5** são usados como base de tempo para triggar eventos de conversão.

#### UART

Usado para transmitir mensagens de status, sinalizando o fim de aquisição (`"FIM"`).

#### LEDs

Duas saídas de LED indicam atividade de DMA para cada canal.

---

## 📁 Estrutura do Repositório

```
dma/
├── main.asm         # Código-fonte principal que inicializa e executa a aplicação
└── (sem README.md)  # Adicione este arquivo na raiz
```

---

## 🧠 Como Funciona (Resumo)

1. Inicializa PLL, ADCs, DMA, Timers, UART e I/Os;
2. DMA faz transferências automáticas sem CPU;
3. Cada vez que um buffer é preenchido, a interrupção do DMA é acionada para processar dados e **piscar o LED correspondente**;
4. Ao receber comando via UART, o processamento é desativado e relatório é enviado.

---

## 🧪 Compilação e Execução

Para compilar e usar este projeto você precisa de:

* **MPLAB X IDE** com compilador **XC16**;
* Placa de desenvolvimento compatível com dsPIC33;
* Configurar os pinos AN0 e AN1 como entradas analógicas.

**Passos de compilação:**

1. Abra o MPLAB X;
2. Importe `main.asm` como parte de um projeto PIC24/dsPIC33;
3. Compile e grave na sua placa.

---

## 🔌 Dependências

Este código assume:

* Processador dsPIC33 com suporte a módulos DMA;
* UART disponível para comunicação;
* LEDs conectados às portas definidas em `main.asm`.

---

## 📬 Contato e Contribuição

Se quiser contribuir, adicionar exemplos ou atualizar a documentação, fique à vontade para abrir uma *issue* ou um *pull request* neste repositório.


