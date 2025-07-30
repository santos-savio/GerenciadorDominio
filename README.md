# Gerenciador de Domínio (PowerShell)

Um utilitário interativo em PowerShell para gerenciar computadores em domínios Windows de forma prática e automatizada.

## ⚙️ Funcionalidades

- ✅ Verificar se o computador está no domínio e status do canal seguro
- 🔧 Reparar canal seguro do domínio
- 🔄 Remover o computador do domínio e ingressá-lo em um grupo de trabalho
- ➕ Adicionar computador ao domínio (com validação de nome de domínio)
- 🔒 Restringir execução de scripts PowerShell
- 📄 Criar e armazenar credenciais de acesso em JSON

## 🧰 Requisitos

- PowerShell 5.1 ou superior
- Execução como administrador
- Execução de scripts habilitada no PowerShell
- Credenciais válidas de administrador de domínio

## 🚀 Como usar

1. Clone ou baixe este repositório:

```bash
   git clone https://github.com/santos-savio/GerenciadorDominio.git
   cd GerenciadorDominio
```

2. Habilite a execução de scripts:

```shell
Set-ExecutionPolicy Unrestricted
```

3. Execute o script no PowerShell com permissões de administrador:

```bash
.\GerenciadorDominio.ps1
```

4. Siga o menu interativo.

🛠️ Criando o arquivo de credenciais
Caso não exista um arquivo cred.json, selecione a opção 6 no menu e forneça os dados solicitados:

Exemplo de cred.json:

```json
{
  "Dominio": "empresa.local",
  "Usuario": "empresa\\admin",
  "Senha": "sua_senha"
}
```
⚠️ A senha será armazenada em texto puro. Use apenas em ambientes seguros e controlados.

🔐 Segurança
A senha é convertida para SecureString em tempo de execução.
Para manter a segurança do ambiente, a execução de scripts no Windows pode ser desativada com a função 5.

🧪 Validação de domínio
Domínios são validados usando a seguinte expressão regular:

^([a-zA-Z0-9]{2,}\.)+[a-zA-Z0-9]{2,}$
Exemplos válidos:

empresa.local

sub.empresa.com

abc.def.123.org

📁 Repositório
https://github.com/santos-savio/GerenciadorDominio

📜 Licença
Este projeto está licenciado sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.