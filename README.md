# volt.sh - Um Gerenciador de Energia Deliberado

"Recuso a terceirização da minha vontade. Automatizar tudo, delegar tudo, depender de tudo — isso me enfraqueceu. Hoje, tudo que posso assumir, eu assumo. Minha vontade é central."

`volt.sh` é um ato de recuperação de controle sobre o hardware. Nascido da necessidade de uma gestão de energia simples e intencional, este projeto evoluiu para um sistema modular robusto, rejeitando a complexidade de ferramentas abstratas em favor da interação direta com o sistema.

O projeto é dividido em dois componentes principais:
* **`volt.sh`**: O motor de controle, um script de linha de comando puro que gerencia os perfis de energia, bateria e brilho.
* **`volt-polybar.sh`**: Um módulo de exibição opcional, projetado para formatar o status do sistema para a Polybar.

## Filosofia / Codicis

* **Vontade sobre o algoritmo**: A ferramenta se molda a mim. Tenho presets para conveniência e controle direto para quando preciso.
* **Construção com as próprias mãos**: Entender e controlar o próprio ambiente é fundamental. Este script é a prova de que o essencial não precisa ser terceirizado.
* **Modularidade e Direção**: Foco na solução direta do problema. A lógica de controle é separada da interface, permitindo que o `volt.sh` seja usado por qualquer pessoa, com ou sem a Polybar.

## Funcionalidades (`volt.sh`)

### Perfis de Energia
* **Economico (`--economico`)**: Ideal para maximizar a duração da bateria.
    * **CPU**: Define o governador para `powersave`.
    * **Tela**: Salva o brilho atual e o reduz para 30%.
    * **Bateria**: Permite carga até 100% (ideal para uso móvel).
* **Normal (`--normal`)**: Focado em longevidade e uso geral.
    * **CPU**: Define o governador para `schedutil` (ou `ondemand` como fallback).
    * **Tela**: Restaura o brilho para o valor anterior ao modo econômico.
    * **Bateria**: Ativa o modo de conservação (limita a carga em ~60%).
* **Desempenho (`--desempenho`)**: Para tarefas intensivas que exigem máximo poder.
    * **CPU**: Define o governador para `performance`.
    * **Tela**: Restaura o brilho para o valor anterior.
    * **Bateria**: Permite carga até 100%.

### Controles Granulares de Bateria
* **Ativar Modo de Conservação (`--on`)**: Limita a carga da bateria a ~60%, independentemente do perfil ativo.
* **Desativar Modo de Conservação (`--off`)**: Permite que a bateria carregue até 100%, independentemente do perfil ativo.

### Status Detalhado (`--status`)
Fornece um resumo completo do estado atual do sistema, incluindo o perfil ativo, o status da bateria, o governador da CPU e o nível de brilho da tela.

## Instalação e Uso

1.  **Clone o repositório e torne os scripts executáveis:**
    ```bash
    git clone git@github.com:seu-usuario/volt.sh.git
    cd volt.sh
    chmod +x volt.sh volt-polybar.sh
    ```

2.  **Crie links simbólicos para uso global (Recomendado):**
    ```bash
    # Link para o motor de controle
    sudo ln -s /caminho/completo/para/volt.sh /usr/local/bin/volt

    # Link para o módulo da Polybar (se você a utiliza)
    sudo ln -s /caminho/completo/para/volt-polybar.sh /usr/local/bin/volt-polybar
    ```

3.  **Uso via terminal:**
    ```bash
    # Aplicar um perfil
    sudo volt --desempenho

    # Controlar a bateria diretamente
    sudo volt --on

    # Verificar o status completo
    volt --status
    ```

4.  **Configure as permissões para a Polybar (Opcional):**
    Para usar os comandos da Polybar sem senha, crie um arquivo com `sudo visudo -f /etc/sudoers.d/volt` e adicione a linha (use o caminho completo):
    ```
    seu-usuario ALL=(ALL) NOPASSWD: /caminho/completo/para/volt.sh
    ```

## Integração com Polybar

Adicione o seguinte módulo à sua configuração da Polybar para um controle completo via mouse. Note que `exec` aponta para o script de exibição, enquanto os cliques apontam para o script de controle.

```ini
[module/volt]
type = custom/script
interval = 5
exec = /caminho/completo/para/volt-polybar.sh
format = <label>
format-underline = "#f92aad" ; ou sua cor preferida
label = %output%

; Ações de Clique para Perfis (usam o motor 'volt'):
click-left = sudo volt --normal
click-middle = sudo volt --desempenho
click-right = sudo volt --economico

; Ação de Scroll para Bateria (usam o motor 'volt'):
scroll-up = sudo volt --off
scroll-down = sudo volt --on
```
---


## Autor

* **sftctrl** - [GitHub](https://github.com/sftctrl)
