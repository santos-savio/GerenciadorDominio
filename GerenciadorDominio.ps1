# GerenciadorDominio.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Menu {
    Clear-Host
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host " GERENCIADOR DE DOMÍNIO - MENU PRINCIPAL " -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "1. Verificar conexão com o domínio" -ForegroundColor Yellow
    Write-Host "2. Reparar conexão com o domínio" -ForegroundColor Yellow
    Write-Host "3. Remover computador do domínio" -ForegroundColor Yellow
    Write-Host "4. Adicionar computador ao domínio" -ForegroundColor Yellow
    Write-Host "5. Bloquear execução de scripts PowerShell" -ForegroundColor Red
    Write-Host "0. Sair" -ForegroundColor Gray
    Write-Host ""
}

function Verificar-Dominio {
    Write-Host "`n=== VERIFICAÇÃO DE DOMÍNIO ===" -ForegroundColor Cyan
    $estaNoDominio = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    if ($estaNoDominio) {
        $dominio = (Get-WmiObject Win32_ComputerSystem).Domain
        Write-Host "✅ O computador está no domínio: $dominio" -ForegroundColor Green
        $canalSeguro = Test-ComputerSecureChannel
        if ($canalSeguro) {
            Write-Host "✅ Canal seguro com o domínio está funcionando." -ForegroundColor Green
        } else {
            Write-Host "❌ Falha no canal seguro. Use a opção 2 para reparar." -ForegroundColor Red
        }
    } else {
        Write-Host "❌ O computador NÃO está em um domínio." -ForegroundColor Red
    }
    Pause
}

function Reparar-Dominio {
    Write-Host "`n=== REPARO DE CONEXÃO COM O DOMÍNIO ===" -ForegroundColor Cyan
    $estaNoDominio = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    if (-not $estaNoDominio) {
        Write-Host "❌ O computador NÃO está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    $credenciais = Get-Credential -Message "Digite as credenciais de administrador do domínio (ex: DOMINIO\admin)"
    try {
        Test-ComputerSecureChannel -Repair -Credential $credenciais -ErrorAction Stop
        Write-Host "✅ Canal seguro reparado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao reparar: $_" -ForegroundColor Red
    }
    Pause
}

function Remover-Dominio {
    Write-Host "`n=== REMOÇÃO DO DOMÍNIO ===" -ForegroundColor Yellow
    $estaNoDominio = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    if (-not $estaNoDominio) {
        Write-Host "❌ O computador já NÃO está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    $credenciais = Get-Credential -Message "Digite as credenciais de administrador do domínio (ex: DOMINIO\admin)"
    try {
        Remove-Computer -UnjoinDomainCredential $credenciais -Force -PassThru -ErrorAction Stop
        Write-Host "✅ Computador removido do domínio. Reinicie para aplicar." -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao remover: $_" -ForegroundColor Red
    }
    Pause
}

function Adicionar-Dominio {
    Write-Host "`n=== ADIÇÃO AO DOMÍNIO ===" -ForegroundColor Cyan
    $estaNoDominio = (Get-WmiObject Win32_ComputerSystem).PartOfDomain
    if ($estaNoDominio) {
        Write-Host "❌ O computador JÁ está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    $nomeDominio = Read-Host "Digite o nome do domínio (ex: EMPRESA.LOCAL)"
    $credenciais = Get-Credential -Message "Digite as credenciais de administrador do domínio (ex: DOMINIO\admin)"
    try {
        Add-Computer -DomainName $nomeDominio -Credential $credenciais -ErrorAction Stop
        Write-Host "✅ Computador adicionado ao domínio. Reinicie para aplicar." -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao adicionar: $_" -ForegroundColor Red
    }
    Pause
}

function Bloquear-Scripts {
    Write-Host "`n=== BLOQUEAR EXECUÇÃO DE SCRIPTS ===" -ForegroundColor Red
    Set-ExecutionPolicy Restricted
    $politicaAtual = get-ExecutionPolicy
    Write-Host "✅ Política definida como $politicaAtual. Scripts bloqueados." -ForegroundColor Green
	
    Write-Host "Get-ExecutionPolicy: "
    Get-ExecutionPolicy
    Pause
}

function Pause {
    Write-Host "`nPressione Enter para continuar..."
    $null = Read-Host
}

# Loop do menu
do {
    Show-Menu
    $opcao = Read-Host "Selecione uma opção (0-5)"
    switch ($opcao) {
        '1' { Verificar-Dominio }
        '2' { Reparar-Dominio }
        '3' { Remover-Dominio }
        '4' { Adicionar-Dominio }
        '5' { Bloquear-Scripts }
        '0' { exit }
        default { Write-Host "Opção inválida!" -ForegroundColor Red; Pause }
    }
} while ($true)