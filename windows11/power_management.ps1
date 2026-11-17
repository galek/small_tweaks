# 1. Enable and activate "High Performance" power plan
powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# 2. OR enable and activate "Ultimate Performance" power plan (recommended for desktops)
$ultimateGuid = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) -replace '.*GUID:\s*([a-f0-9-]+).*', '$1'
if ($ultimateGuid -match '^[a-f0-9-]+$') {
    powercfg -setactive $ultimateGuid
}
