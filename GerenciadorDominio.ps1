# GerenciadorDominio.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Mensagem inicial e captura das credenciais
Write-Host "Este script requer credenciais de administrador do domínio para executar operações de domínio." -ForegroundColor Cyan
Write-Host "As credenciais serão solicitadas agora e usadas automaticamente nas operações necessárias." -ForegroundColor Yellow
Write-Host "Pressione qualquer tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$Global:Credenciais = Get-Credential -Message "Digite as credenciais de administrador do domínio (ex: DOMINIO\admin)"

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
    Write-Host "0. Sair" -ForegroundColor Gray
    Write-Host ""
}

function Get-DominioStatus {
    Write-Host "`n=== STATUS DO DOMÍNIO ===" -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.PartOfDomain) {
        Write-Host "✅ O computador está no domínio: $($cs.Domain)" -ForegroundColor Green
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

function Repair-DominioSecureChannel {
    Write-Host "`n=== REPARO DE CANAL SEGURO DO DOMÍNIO ===" -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystem
    if (-not $cs.PartOfDomain) {
        Write-Host "❌ O computador NÃO está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    try {
        Test-ComputerSecureChannel -Repair -Credential $Global:Credenciais -ErrorAction Stop
        Write-Host "✅ Canal seguro reparado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao reparar: $_" -ForegroundColor Red
    }
    Pause
}

function Remove-Dominio {
    Write-Host "`n=== REMOÇÃO DO DOMÍNIO ===" -ForegroundColor Yellow
    $cs = Get-CimInstance Win32_ComputerSystem
    if (-not $cs.PartOfDomain) {
        Write-Host "❌ O computador já NÃO está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    $workgroup = Read-Host "Digite o nome do grupo de trabalho para o qual deseja mover o computador (ex: WORKGROUP)"
    try {
        Remove-Computer -UnjoinDomainCredential $Global:Credenciais -WorkgroupName $workgroup -Force -PassThru -ErrorAction Stop
        Write-Host "✅ Computador removido do domínio e movido para o grupo de trabalho '$workgroup'. Reinicie para aplicar." -ForegroundColor Green
    } catch {
        Write-Host "❌ Falha ao remover: $_" -ForegroundColor Red
    }
    Pause
}

function Add-Dominio {
    Write-Host "`n=== ADIÇÃO AO DOMÍNIO ===" -ForegroundColor Cyan
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.PartOfDomain) {
        Write-Host "❌ O computador JÁ está em um domínio." -ForegroundColor Red
        Pause
        return
    }
    $nomeDominio = Read-Host "Digite o nome do domínio (ex: EMPRESA.LOCAL)"
    try {
        Add-Computer -DomainName $nomeDominio -Credential $Global:Credenciais -ErrorAction Stop
        Write-Host "✅ Computador adicionado ao domínio. Reinicie para aplicar." -ForegroundColor Green
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

function Pause {
    Write-Host "`nPressione Enter para continuar..."
    $null = Read-Host
}

# Loop do menu
do {
    Show-Menu
    $opcao = Read-Host "Selecione uma opção (0-5)"
    switch ($opcao) {
        '1' { Get-DominioStatus }
        '2' { Repair-DominioSecureChannel }
        '3' { Remove-Dominio }
        '4' { Add-Dominio }
        '5' { Set-ScriptExecutionPolicyRestricted }
        '0' { exit }
        default { Write-Host "Opção inválida!" -ForegroundColor Red; Pause }
    }
} while ($true)