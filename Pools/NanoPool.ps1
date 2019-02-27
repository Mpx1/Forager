param(
    [Parameter(Mandatory = $false)]
    [String]$Querymode = $null,
    [Parameter(Mandatory = $false)]
    [PSCustomObject]$Info
)

#. .\Include.ps1

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$ActiveOnManualMode = $true
$ActiveOnAutomaticMode = $true
$ActiveOnAutomatic24hMode = $true
$WalletMode = "Wallet"
$RewardType = "PPLS"
$Result = @()

if ($Querymode -eq "Info") {
    $Result = [PSCustomObject]@{
        Disclaimer               = "No registration, No autoexchange, need wallet for each coin"
        ActiveOnManualMode       = $ActiveOnManualMode
        ActiveOnAutomaticMode    = $ActiveOnAutomaticMode
        ActiveOnAutomatic24hMode = $ActiveOnAutomatic24hMode
        ApiData                  = $true
        WalletMode               = $WalletMode
        RewardType               = $RewardType
    }
}

if ($Querymode -eq "Speed") {
    $Request = Invoke-APIRequest -Url $("https://api.nanopool.org/v1/" + $Info.Symbol.ToLower() + "/history/" + $Info.User) -Retry 1
    if ($Request) {
        $Result = [PSCustomObject]@{
            PoolName   = $Name
            WorkerName = $Info.WorkerName
            HashRate   = ($Request.data)[0].HashRate
        }
    }
}

if ($Querymode -eq "Wallet") {
    $Request = Invoke-APIRequest -Url $("https://api.nanopool.org/v1/" + $Info.Symbol.ToLower() + "/balance/" + $Info.User) -Retry 3
    if ($Request) {
        $Result = [PSCustomObject]@{
            Pool     = $Name
            Currency = $Info.Symbol
            Balance  = $Request.Data
        }
    }
}

if ($Querymode -eq "Core") {

    $Pools = @(
        [PSCustomObject]@{ Coin = "Ethereum"        ; Symbol = "ETH"  ; Algo = "Ethash"    ; WalletSymbol = "ETH"    ; Port = 9999  ; Fee = 0.01 ; Divisor = 1e6 }
        [PSCustomObject]@{ Coin = "EthereumClassic" ; Symbol = "ETC"  ; Algo = "Ethash"    ; WalletSymbol = "ETC"    ; Port = 19999 ; Fee = 0.01 ; Divisor = 1e6 }
        [PSCustomObject]@{ Coin = "Monero"          ; Symbol = "XMR"  ; Algo = "CnV8"      ; WalletSymbol = "XMR"    ; Port = 14444 ; Fee = 0.01 ; Divisor = 1   ; PortSSL = 14433}
        [PSCustomObject]@{ Coin = "Pascalcoin"      ; Symbol = "PASC" ; Algo = "RandomHash"; WalletSymbol = "PASC"   ; Port = 15556 ; Fee = 0.02 ; Divisor = 1   }
        [PSCustomObject]@{ Coin = "Raven"           ; Symbol = "RVN"  ; Algo = "X16r"      ; WalletSymbol = "RVN"    ; Port = 12222 ; Fee = 0.01 ; Divisor = 1e6 }
        [PSCustomObject]@{ Coin = "Grin"            ; Symbol = "GRIN" ; Algo = "Cuckaroo29"; WalletSymbol = "GRIN29" ; Port = 12111 ; Fee = 0.01 ; Divisor = 1e6 }
    )

    #generate a pool for each location and add API data
    $Result = $Pools | Where-Object {$Wallets.($_.Symbol) -ne $null} | ForEach-Object {
        $RequestW = Invoke-APIRequest -Url $("https://api.nanopool.org/v1/" + $_.WalletSymbol.ToLower() + "/pool/activeworkers") -Retry 1
        $RequestP = Invoke-APIRequest -Url $("https://api.nanopool.org/v1/" + $_.WalletSymbol.ToLower() + "/approximated_earnings/1000") -Retry 1

        $Locations = @(
            [PSCustomObject]@{ Location = "Eu"    ; Server = $_.WalletSymbol + "-eu1.nanopool.org" }
            [PSCustomObject]@{ Location = "US"    ; Server = $_.WalletSymbol + "-us-east1.nanopool.org" }
            [PSCustomObject]@{ Location = "Asia"  ; Server = $_.WalletSymbol + "-asia1.nanopool.org" }
        )

        ForEach ($Loc in $Locations) {
            [PSCustomObject]@{
                Algorithm             = $_.Algo
                Info                  = $_.Coin
                Price                 = [decimal]$RequestP.data.day.bitcoins / $_.Divisor / 1000
                Protocol              = "stratum+tcp"
                ProtocolSSL           = "stratum+tls"
                Host                  = $Loc.Server
                Port                  = $_.Port
                PortSSL               = $_.PortSSL
                User                  = $Wallets.($_.Symbol)
                Pass                  = "x"
                Location              = $Loc.Location
                SSL                   = [bool]$PortSSL
                Symbol                = $_.Symbol
                ActiveOnManualMode    = $ActiveOnManualMode
                ActiveOnAutomaticMode = $ActiveOnAutomaticMode
                PoolWorkers           = $RequestW.Data
                PoolName              = $Name
                WalletMode            = $WalletMode
                WalletSymbol          = $_.WalletSymbol
                Fee                   = $_.Fee
                EthStMode             = 0
                RewardType            = $RewardType
            }
        }
        Start-Sleep -Milliseconds 250 # Prevent API Saturation
    }
}

$Result
Remove-Variable Result
