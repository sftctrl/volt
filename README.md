# volt.sh - Um Gerenciador de Energia Deliberado

"Recuso a terceirização da minha vontade. Automatizar tudo, delegar tudo, depender de tudo — isso me enfraqueceu. Hoje, tudo que posso assumir, eu assumo. Minha vontade é central."

`volt.sh` é mais que um script; é um ato de recuperação de controle. Nasce da necessidade de gerenciar a energia do meu notebook de forma simples e intencional, rejeitando a complexidade de ferramentas que escondem suas operações por trás de camadas de abstração.

Este projeto substitui o `tlp` para controlar diretamente o **limiar de carga da bateria**, resolvendo o problema comum de notebooks que param de carregar em ~60% para preservar a longevidade do hardware.

## Filosofia / Codicis

* **Vontade sobre o algoritmo**: A ferramenta deve se moldar a mim, não o contrário. Este script faz uma única coisa, de forma explícita e sob meu comando.
* **Construção com as próprias mãos**: Entender e controlar o próprio ambiente é fundamental. Este script é a prova de que o essencial não precisa ser terceirizado.
* **Simplicidade e Direção**: Foco na solução direta do problema, sem funcionalidades excessivas que geram ruído e distração.

## Funcionalidades

* **Ativar Modo de Conservação**: Limita a carga da bateria a 60%, ideal para quando o notebook está na tomada por longos períodos.
* **Desativar Modo de Conservação**: Permite que a bateria carregue até 100%, necessário para quando se precisa de mobilidade.
* **Verificar Status**: Mostra o modo atual de operação.
* **Integração com Polybar**: Exibe o status de forma clara e minimalista na sua barra.

## Instalação e Uso

1.  **Clone o repositório:**
    ```bash
    git clone git@github.com:seu-usuario/volt.sh.git
    cd volt.sh
    ```

2.  **Torne o script executável:**
    ```bash
    chmod +x volt.sh
    ```

3.  **Uso via terminal:**
    ```bash
    # Para ativar o modo de conservação (carga máxima de 60%)
    ./volt.sh --on

    # Para desativar o modo de conservação (permitir carga até 100%)
    ./volt.sh --off

    # Para verificar o status atual
    ./volt.sh --status
    ```
    *Nota: Pode ser necessário rodar com `sudo` na primeira vez ou criar uma regra `udev` para permitir que seu usuário modifique o arquivo de controle.*

4.  **Integração com Polybar:**
    * Copie o conteúdo de `polybar-module.ini` para o arquivo `config.ini` da sua Polybar.
    * Adicione o módulo `volt` à sua `modules-right` (ou onde preferir).
    * Recarregue a Polybar.

---

## Autor

* **sftctrl** - [GitHub](https://github.com/sftctrl)
