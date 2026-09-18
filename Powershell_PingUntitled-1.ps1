1..254 | ForEach-Object {
    $ip = "192.168.1.$_"
    if (Test-Connection $ip -Count 1 -Quiet -TimeoutSeconds 1) {
        Write-Host "$ip ONLINE"
    }
}