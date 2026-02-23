# Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "Requesting administrator privileges..."

    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs
    exit
}

$IniPath = "$PSScriptRoot\servers.ini"

function Read-DNSList {
    $dnsList = @()

    if (-not (Test-Path $IniPath)) {
        Write-Host "INI file not found."
        return $dnsList
    }

    Get-Content $IniPath | ForEach-Object {
        if ($_ -match "=") {
            $name, $values = $_ -split "=", 2
            $dnsServers = $values -split ","

            $dnsList += [PSCustomObject]@{
                Name = $name.Trim()
                DNS  = $dnsServers
            }
        }
    }

    return $dnsList
}

function Select-And-SetDNS {
    while ($true) {
        Clear-Host
        $dnsList = Read-DNSList

        if ($dnsList.Count -eq 0) {
            Write-Host "DNS list is empty."
            Pause
            return
        }

        Write-Host "Available DNS Servers:`n"

        for ($i = 0; $i -lt $dnsList.Count; $i++) {
            Write-Host "$($i + 1). $($dnsList[$i].Name) -> $($dnsList[$i].DNS -join ', ')"
        }

        Write-Host "`n0. Back"
        $choice = Read-Host "`nSelect DNS number"

        if ($choice -eq "0") {
            return
        }

        if ($choice -lt 1 -or $choice -gt $dnsList.Count) {
            Write-Host "Invalid selection."
            Pause
            continue
        }

        $selected = $dnsList[$choice - 1]
        Write-Host "`nSetting DNS: $($selected.Name)"
        Write-Host "Step 1: Detecting active network adapters..."

        try {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

            if ($adapters.Count -eq 0) {
                throw "No active network adapters found."
            }

            foreach ($adapter in $adapters) {
                Write-Host "Applying DNS to adapter: $($adapter.Name)"
                Set-DnsClientServerAddress `
                    -InterfaceIndex $adapter.InterfaceIndex `
                    -ServerAddresses $selected.DNS
            }

            Write-Host "`nDNS successfully applied."
        }
        catch {
            Write-Host "`nFailed to set DNS."
            Write-Host "Error: $_"
        }

        Pause
        return
    }
}

function Add-DNSToList {
    while ($true) {
        Clear-Host
        Write-Host "Add New DNS"
        Write-Host "0. Back`n"

        $name = Read-Host "DNS Name (or 0 to go back)"
        if ($name -eq "0") { return }

        $dns1 = Read-Host "Primary DNS (or 0 to go back)"
        if ($dns1 -eq "0") { return }

        $dns2 = Read-Host "Secondary DNS (or 0 to go back)"
        if ($dns2 -eq "0") { return }

        try {
            "$name=$dns1,$dns2" | Add-Content $IniPath
            Write-Host "`nDNS added successfully."
        }
        catch {
            Write-Host "`nFailed to add DNS."
            Write-Host "Error: $_"
        }

        Pause
        return
    }
}

function Flush-DNS {
    while ($true) {
        Clear-Host
        Write-Host "Flush DNS Cache"
        Write-Host "0. Back`n"

        $confirm = Read-Host "Press ENTER to continue or 0 to go back"
        if ($confirm -eq "0") { return }

        Write-Host "`nFlushing DNS cache..."
        try {
            ipconfig /flushdns | Out-Null
            Write-Host "DNS cache flushed successfully."
        }
        catch {
            Write-Host "Failed to flush DNS cache."
            Write-Host "Error: $_"
        }

        Pause
        return
    }
}

# ──────────────────────────────────────────────
# ✅ تابع جدید: بازگشت DNS به حالت پیشفرض
# ──────────────────────────────────────────────
function Reset-DNSToDefault {
    while ($true) {
        Clear-Host
        Write-Host "Reset DNS to Default (Automatic / DHCP)"
        Write-Host "0. Back`n"

        $confirm = Read-Host "Press ENTER to reset or 0 to go back"
        if ($confirm -eq "0") { return }

        Write-Host "`nResetting DNS to default..."

        try {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

            if ($adapters.Count -eq 0) {
                throw "No active network adapters found."
            }

            foreach ($adapter in $adapters) {
                Write-Host "Resetting DNS on adapter: $($adapter.Name)"

                # ⬇️ این دستور DNS دستی را حذف کرده و به DHCP برمی‌گرداند
                Set-DnsClientServerAddress `
                    -InterfaceIndex $adapter.InterfaceIndex `
                    -ResetServerAddresses
            }

            Write-Host "`nDNS successfully reset to default (Automatic)."
        }
        catch {
            Write-Host "`nFailed to reset DNS."
            Write-Host "Error: $_"
        }

        Pause
        return
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Host "==== DNS Manager ===="
    Write-Host "1. Select & Set DNS"
    Write-Host "2. Add DNS to List"
    Write-Host "3. Flush DNS"
    Write-Host "4. Reset DNS to Default"    # ← گزینه جدید
    Write-Host "0. Exit"
}

do {
    Show-MainMenu
    $input = Read-Host "Choose an option"

    switch ($input) {
        "1" { Select-And-SetDNS }
        "2" { Add-DNSToList }
        "3" { Flush-DNS }
        "4" { Reset-DNSToDefault }          # ← گزینه جدید
        "0" { break }
        default {
            Write-Host "Invalid option."
            Pause
        }
    }
} while ($true)