# GerenciadorDominio.ps1

# Define codificação para UTF-8 no console (evita problemas com acentos e caracteres especiais)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Tentativa de leitura do arquivo de credenciais JSON
try {
    $cred = Get-Content .\cred.json | ConvertFrom-Json -ErrorAction Stop
    Write-Host "Leitura do json concluída"
}
catch {
    # Exibe erro se a leitura ou conversão falhar
    Write-Host "Erro de leitura do json: $_"
    Pause
    exit
}

# Converte a senha (em texto puro) para formato seguro
$securePass = ConvertTo-SecureString $cred.Senha -AsPlainText -Force
# Cria objeto de credencial usando usuário e senha
$psCred = New-Object System.Management.Automation.PSCredential ($cred.Usuario, $securePass)
$Credenciais = $psCred

# Mensagem de boas-vindas e instrução
Write-Host "Este script requer credenciais de administrador do domínio para executar as operações." -ForegroundColor Cyan
Write-Host "Use a função 6 para criar um arquivo de acesso." -ForegroundColor Cyan
Write-Host "Pressione qualquer tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Exibe menu principal com opções
function Show-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host " GERENCIADOR DE DOMÍNIO - MENU PRINCIPAL " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "1. Obter status do domínio" -ForegroundColor Yellow
    Write-Host "2. Reparar canal seguro do domínio" -ForegroundColor Yellow
    Write-Host "3. Remover computador do domínio" -ForegroundColor Yellow
    Write-Host "4. Adicionar computador ao domínio" -ForegroundColor Yellow
    Write-Host "5. Restringir execução de scripts PowerShell" -ForegroundColor Red
    Write-Host "6. Criar arquivo de acesso" -ForegroundColor Yellow
    Write-Host "0. Sair" -ForegroundColor Gray
    Write-Host ""
}

# Verifica se o computador está no domínio e o status do canal seguro
function Get-DominioStatus {
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host "`n=== STATUS DO DOMÍNIO ===" -ForegroundColor Cyan
    if ($cs.PartOfDomain) {
        Write-Host "✅ O computador está no domínio: $($cs.Domain)" -ForegroundColor Green
        $canalSeguro = Test-ComputerSecureChannel
        if ($canalSeguro) {
            Write-Host "✅ Canal seguro com o domínio está funcionando." -ForegroundColor Green
        } else {
            Write-Host "❌ Falha no canal seguro. Tente a opção 2 para reparar ou remova e adicione novamente." -ForegroundColor Red
        }
    } else {
        Write-Host "❌ O computador NÃO está em um domínio." -ForegroundColor Red
    }
    Pause
}

# Repara o canal seguro com o domínio, se necessário
function Repair-DominioSecureChannel {
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host "`n=== REPARO DE CANAL SEGURO DO DOMÍNIO ===" -ForegroundColor Cyan
    if (-not $cs.PartOfDomain) {
        Write-Host "❌ O computador NÃO está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    try {
        Test-ComputerSecureChannel -Repair -Credential $Credenciais -ErrorAction Stop
        Write-Host "✅ Canal seguro reparado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao reparar: $_" -ForegroundColor Red
    }
    Pause
}

# Remove o computador do domínio e adiciona ao grupo de trabalho
function Remove-Dominio {
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host "`n=== REMOÇÃO DO DOMÍNIO ===" -ForegroundColor Yellow
    if (-not $cs.PartOfDomain) {
        Write-Host "❌ O computador NÃO está ingressado em um domínio." -ForegroundColor Red
        Pause
        return
    }
    try {
        Remove-Computer -UnjoinDomainCredential $Credenciais -WorkgroupName WORKGROUP -Force -ErrorAction Stop
        Write-Host "✅ Computador removido do domínio e movido para o grupo de trabalho 'WORKGROUP'. Reinicie para aplicar." -ForegroundColor Green
        $optReiniciar = Read-Host "Digite S para reiniciar"
        if ($optReiniciar -eq "s") {
            Restart-Computer -Force
        }
    } catch {
        Write-Host "❌ Falha ao remover: $_" -ForegroundColor Red
        try {
            Add-Computer -WorkgroupName "WORKGROUP" -Force
        }
        catch {
            Write-Host "❌ Falha ao ingressar no workgroup: $_" -ForegroundColor Red
        }
    }
    Pause
}


# Adiciona o computador ao domínio
function Add-Dominio {
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host "`n=== ADIÇÃO AO DOMÍNIO ===" -ForegroundColor Cyan
    if ($cs.PartOfDomain) {
        Write-Host "❌ O computador JÁ está em um domínio." -ForegroundColor Red
        Pause
        return
    }

    $dominio = $cred.Dominio

    $regexDominio = '^([a-zA-Z0-9-]{1,}\.)+[a-zA-Z]{2,}$'

    if (!($dominio)) {
        $dominio = Read-Host "Digite o nome do domínio (ex: EMPRESA.LOCAL)"
    }
    if (!($dominio -match $regexDominio)) {
        Write-Host "❌ Nome de domínio inválido: $dominio. Use o formato: EMPRESA.LOCAL" -ForegroundColor Red
        $dominio = Read-Host "Digite o nome do domínio (ex: EMPRESA.LOCAL)"
        }

    try {
        Add-Computer -DomainName $dominio -Credential $Credenciais -ErrorAction Stop
        Write-Host "✅ Computador adicionado ao domínio. Reinicie para aplicar." -ForegroundColor Green
        $option = Read-Host "Pressione 1 para desativar a execução de scripts e reiniciar o computador"
        if ($option -eq '1') {
            Write-Host "Desativando a execução de scripts e reiniciando o computador..." -ForegroundColor Yellow
            try {
                Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
                Set-ExecutionPolicy Restricted -Scope localMachine -Force
            }
            catch {
                Write-Host "❌ Falha ao desativar a execução de scripts: $_" -ForegroundColor Red
            }
            Restart-Computer -Force
        }
    } catch {
        Write-Host "❌ Falha ao adicionar: $_" -ForegroundColor Red
    }
    Pause
}

# Restringe execução de scripts PowerShell no usuário atual (Padrão do windows)
function Set-ScriptExecutionPolicyRestricted {
    Write-Host "`n=== RESTRINGIR EXECUÇÃO DE SCRIPTS ===" -ForegroundColor Red
    Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
    Set-ExecutionPolicy Restricted -Scope LocalMachine
    $politicaAtualUsuario = Get-ExecutionPolicy -Scope CurrentUser
    $politicaAtualMaquina = Get-ExecutionPolicy -Scope LocalMachine
    Write-Host "✅ Política do usuário definida como $politicaAtualUsuario." -ForegroundColor Green
    Write-Host "✅ Política do computador local definida como $politicaAtualMaquina." -ForegroundColor Green
    Pause 
}

# Cria um novo arquivo JSON com as credenciais de acesso ao domínio
function New-DomainCredentialFile  {
    Write-Host "`n=== CRIAR CREDENCIAIS ===" -ForegroundColor Cyan
    Write-Host "Atenção! A senha é salva no arquivo 'cred.json' como texto puro, mantenha em segurança." -ForegroundColor Yellow
    
    if ((Test-Path -Path "cred.json")) {
        Write-Host ""
        $sobreescrever = Read-Host "O arquivo 'cred.json' já existe, deseja sobreescrever? (s/n)" -ForegroundColor Yellow
        if ($sobreescrever -ne 's') {
            Write-Host "Operação cancelada." -ForegroundColor Red
            Pause
            return
        } else {
            Remove-Item -Path "cred.json" -Force
        }
    } else {
        Write-Host "Mantenha este arquivo protegido e remova-o após o uso!" -ForegroundColor Red
        Write-Host ""   
        $acessInfo = @{
            Dominio = Read-Host -Prompt "Digite o nome do domínio (ex: EMPRESA.LOCAL)"
            Usuario = Read-Host -Prompt "Digite o nome de usuário (ex: dominio\usuario)"
            Senha = Read-Host -Prompt "Digite a senha do usuário"
        }
        $acessInfo | ConvertTo-Json | Out-File -FilePath "cred.json" -Encoding UTF8
        Write-Host "Arquivo JSON criado com sucesso em: $((Get-Item "cred.json").FullName)"
        Write-Host "✅ Credenciais salvas com sucesso!" -ForegroundColor Green
    }
    Pause
    
}

# Aguarda usuário pressionar Enter, possibilitando ler o retorno do terminal
function Pause {
    Write-Host "`nPressione Enter para continuar..."
    $null = Read-Host
}

# Loop do menu principal
do {
    Show-Menu
    $opcao = Read-Host "Selecione uma opção (0-6)"
    switch ($opcao) {
        '1' { Get-DominioStatus }
        '2' { Repair-DominioSecureChannel }
        '3' { Remove-Dominio }
        '4' { Add-Dominio }
        '5' { Set-ScriptExecutionPolicyRestricted }
        '6' { New-DomainCredentialFile }
        "github" {start-process "https://github.com/santos-savio/GerenciadorDominio.git"}
        '0' { exit }
        default { Write-Host "Opção inválida!" -ForegroundColor Red;
        Pause }
    }
} while ($true)