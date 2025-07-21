# volt.sh - Um Gerenciador de Energia Deliberado

"Recuso a terceirização da minha vontade. Automatizar tudo, delegar tudo, depender de tudo — isso me enfraqueceu. Hoje, tudo que posso assumir, eu assumo. Minha vontade é central."

`volt.sh` é um ato de recuperação de controle sobre o hardware. Nascido da necessidade de uma gestão de energia simples e intencional, este script evoluiu para um painel de controle completo, rejeitando a complexidade de ferramentas abstratas em favor da interação direta com o sistema.

Ele implementa um sistema de controle duplo: **Perfis de Energia** para ajustes amplos e **Controles Granulares de Bateria** para ações imediatas, tudo integrado à sua barra de status.

## Filosofia / Codicis

* **Vontade sobre o algoritmo**: A ferramenta se molda a mim. Tenho presets para conveniência e controle direto para quando preciso.
* **Construção com as próprias mãos**: Entender e controlar o próprio ambiente é fundamental. Este script é a prova de que o essencial não precisa ser terceirizado.
* **Simplicidade e Direção**: Foco na solução direta do problema, interagindo com os arquivos de sistema sempre que possível, sem funcionalidades excessivas que geram ruído.

## Funcionalidades

### Perfis de Energia
* **Economico (`--economico`)**: Ideal para maximizar a duração da bateria.
    * **CPU**: Define o governador para `powersave`.
    * **Tela**: Reduz o brilho para 30%.
    * **Bateria**: Permite carga até 100% (ideal para uso móvel).
* **Normal (`--normal`)**: Focado em longevidade e uso geral.
    * **CPU**: Define o governador para `schedutil` (ou `ondemand` como fallback).
    * **Tela**: Não altera o brilho, respeitando a sua escolha.
    * **Bateria**: Ativa o modo de conservação (limita a carga em ~60%).
* **Desempenho (`--desempenho`)**: Para tarefas intensivas que exigem máximo poder.
    * **CPU**: Define o governador para `performance`.
    * **Tela**: Não altera o brilho.
    * **Bateria**: Permite carga até 100%.

### Controles Granulares de Bateria
* **Ativar Modo de Conservação (`--on`)**: Limita a carga da bateria a ~60%, independentemente do perfil ativo.
* **Desativar Modo de Conservação (`--off`)**: Permite que a bateria carregue até 100%, independentemente do perfil ativo.

### Status Detalhado (`--status`)
Fornece um resumo completo do estado atual do sistema, incluindo o perfil ativo, o status da bateria, o governador da CPU e o nível de brilho da tela.

## Instalação e Uso

1.  **Clone o repositório e torne o script executável:**
    ```bash
    git clone git@github.com:seu-usuario/volt.sh.git
    cd volt.sh
    chmod +x volt.sh
    ```

2.  **Crie um link simbólico para uso global (Recomendado):**
    ```bash
    sudo ln -s /caminho/completo/para/volt.sh /usr/local/bin/volt
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

Adicione o seguinte módulo à sua configuração da Polybar para um controle completo via mouse:

```ini
[module/volt]
type = custom/script
interval = 5
exec = /caminho/completo/para/volt.sh --polybar
format = <label>
format-underline = "#f92aad" ; ou sua cor preferida
label = %output%

; Ações de Clique para Perfis:
click-left = sudo /caminho/completo/para/volt.sh --normal
click-middle = sudo /caminho/completo/para/volt.sh --desempenho
click-right = sudo /caminho/completo/para/volt.sh --economico

; Ação de Scroll para Bateria:
scroll-up = sudo /caminho/completo/para/volt.sh --off
scroll-down = sudo /caminho/completo/para/volt.sh --on
```
---


## Autor

* **sftctrl** - [GitHub](https://github.com/sftctrl)
