# GerenciadorDominio.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001

try {
    $cred = Get-Content .\cred.json | ConvertFrom-Json -ErrorAction Stop
    Write-Host "Leitura do json concluída"
}
catch {
    <#Do this if a terminating exception happens#>
    Write-Host "Erro de leitura do json: $_"
    Pause
}
$securePass = ConvertTo-SecureString $cred.Senha -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential ($cred.Usuario, $securePass)
$Credenciais = $psCred

$cs = Get-CimInstance Win32_ComputerSystem

# Mensagem inicial e captura das credenciais
Write-Host "Este script requer credenciais de administrador do domínio para executar as operações." -ForegroundColor Cyan
Write-Host "Use a função 6 para criar um arquivo de acesso." -ForegroundColor Cyan
Write-Host "Pressione qualquer tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

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

function Get-DominioStatus {
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

function Repair-DominioSecureChannel {
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

function Remove-Dominio {
    Write-Host "`n=== REMOÇÃO DO DOMÍNIO ===" -ForegroundColor Yellow
    if (-not $cs.PartOfDomain) {
        Write-Host "❌ O computador já NÃO está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    try {
        Remove-Computer -UnjoinDomainCredential $Credenciais -WorkgroupName WORKGROUP -Force -Restart -ErrorAction Stop
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

function Add-Dominio {
    Write-Host "`n=== ADIÇÃO AO DOMÍNIO ===" -ForegroundColor Cyan
    if ($cs.PartOfDomain) {
        Write-Host "❌ O computador JÁ está em um domínio." -ForegroundColor Red
        Pause
        return
    }

    $dominio = $cred.dominio

    $regexDominio = ^([a-zA-Z0-9]{2,}\.)+[a-zA-Z0-9]{2,}$

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
                Set-ExecutionPolicy Restricted -Scope localMachine
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

function Set-ScriptExecutionPolicyRestricted {
    Write-Host "`n=== RESTRINGIR EXECUÇÃO DE SCRIPTS ===" -ForegroundColor Red
    Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
    $politicaAtual = Get-ExecutionPolicy -Scope CurrentUser
    Write-Host "✅ Política definida como $politicaAtual. Scripts bloqueados para o usuário atual." -ForegroundColor Green
    Pause
}

function New-DomainCredentialFile  {
    Write-Host "`n=== CRIAR CREDENCIAIS ===" -ForegroundColor Cyan
    
    if ((Test-Path -Path "cred.json")) {
        Write-Host "Arquivo cred.json já existe. Salve ou delete antes de criar um novo arquivo." -ForegroundColor Yellow
    } else {
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

function Pause {
    Write-Host "`nPressione Enter para continuar..."
    $null = Read-Host
}

# Loop do menu
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