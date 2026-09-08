<#
.SYNOPSIS
    Keeps an NSG inbound rule pinned to this machine's current public IP.

.DESCRIPTION
    The GOAD/SCCM lab NSGs in this subscription lose their custom security
    rules: the rule is created successfully, then later the NSG is found with
    zero rules and SSH to the jumpbox stops answering. No delete shows up in
    the subscription activity log, and the subscription is governed by
    management-group policies from an external (Microsoft MCAPS) tenant, so the
    cause is outside this subscription's control.

    A cloud-hosted guard cannot solve this on its own: it only sees its own
    outbound address, never this machine's. And an Azure Functions consumption
    app cannot even be created here, because StorageAccountPublicNetworkModify
    forces publicNetworkAccess=Disabled on the storage account it requires.

    So the guard runs here instead. Every $IntervalSeconds it:
      * resolves this machine's current public IP
      * reads the target rule
      * rewrites it ONLY when it is missing or points at a different IP

    Drift-only writes matter. Rewriting every 30s would be ~2,880 ARM writes a
    day, which floods the activity log and risks ARM throttling - and it would
    bury the evidence of what is removing the rules. Writing only on drift
    keeps the log meaningful: every RESTORED line below is a real removal, with
    a timestamp, which is the data needed to identify the culprit.

.PARAMETER Targets
    Each entry is a hashtable: ResourceGroup, Nsg, Rule, Priority, Ports.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File C:\Users\SNaiL\nsg-ip-guard.ps1
    powershell -ExecutionPolicy Bypass -File C:\Users\SNaiL\nsg-ip-guard.ps1 -Once
#>
[CmdletBinding()]
param(
    [int]    $IntervalSeconds = 30,
    [switch] $Once,
    [string] $LogPath = "$env:USERPROFILE\nsg-ip-guard.log",
    [array]  $Targets = @(
        @{ ResourceGroup = 'SCCM-2eedc2-sccm-azure'; Nsg = 'SCCM-subnet-nsg';  Rule = 'AllowSSHInboundOnly'; Priority = 100; Ports = '22' }
    )
)

function Write-Log {
    param([string]$Level, [string]$Message)
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Output $line
    try { Add-Content -Path $LogPath -Value $line -ErrorAction Stop } catch { }
}

function Get-PublicIp {
    foreach ($u in @('https://api.ipify.org', 'https://ifconfig.me/ip', 'https://icanhazip.com')) {
        try {
            $ip = (Invoke-RestMethod -Uri $u -TimeoutSec 10 -ErrorAction Stop).ToString().Trim()
            if ($ip -match '^\d{1,3}(\.\d{1,3}){3}$') { return $ip }
        } catch { }
    }
    return $null
}

function Sync-Rule {
    param($Target, [string]$Ip)

    $cidr = "$Ip/32"
    # --output tsv keeps this cheap; a missing rule yields an empty string.
    $current = & az network nsg rule show `
        --resource-group $Target.ResourceGroup `
        --nsg-name       $Target.Nsg `
        --name           $Target.Rule `
        --query          sourceAddressPrefix `
        --output         tsv 2>$null

    if ($LASTEXITCODE -eq 0 -and $current -eq $cidr) { return 'ok' }

    $verb = if ($LASTEXITCODE -eq 0) { 'update' } else { 'create' }
    $args = @(
        'network','nsg','rule',$verb,
        '--resource-group', $Target.ResourceGroup,
        '--nsg-name',       $Target.Nsg,
        '--name',           $Target.Rule,
        '--priority',       $Target.Priority,
        '--direction','Inbound','--access','Allow','--protocol','Tcp',
        '--source-address-prefixes',      $cidr,
        '--source-port-ranges',           '*',
        '--destination-address-prefixes', '*',
        '--destination-port-ranges',      $Target.Ports,
        '--output','none'
    )
    & az @args 2>$null
    if ($LASTEXITCODE -ne 0) { return 'failed' }

    if ($verb -eq 'create') { return 'restored' } else { return 'moved' }
}

Write-Log 'INFO' "guard starting (interval ${IntervalSeconds}s, $($Targets.Count) target(s), log $LogPath)"

$lastIp = $null
while ($true) {
    $ip = Get-PublicIp
    if (-not $ip) {
        Write-Log 'WARN' 'could not resolve public IP, will retry'
    }
    else {
        if ($ip -ne $lastIp) {
            Write-Log 'INFO' "public IP is $ip"
            $lastIp = $ip
        }
        foreach ($t in $Targets) {
            $where = "$($t.ResourceGroup)/$($t.Nsg)/$($t.Rule)"
            switch (Sync-Rule -Target $t -Ip $ip) {
                'restored' { Write-Log 'RESTORED' "$where was MISSING - recreated for $ip/32" }
                'moved'    { Write-Log 'UPDATED'  "$where repointed to $ip/32" }
                'failed'   { Write-Log 'ERROR'    "$where could not be written (az login expired?)" }
                default    { }   # already correct, stay quiet
            }
        }
    }
    if ($Once) { break }
    Start-Sleep -Seconds $IntervalSeconds
}
