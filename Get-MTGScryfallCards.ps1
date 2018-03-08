class Card
{
    [string] $ID 
    [string] $Name 
    [string] $Cost 
    [string] $Type 
    [string] $Power 
    [string] $Toughness 
    [string] $Text 
    [string] $Set 
    [string] $Rarity 
    [string] $Ctype
    [string] $ConvertedManaCost 
    [string] $ImageURL  
    [string] $ColorIdentity
}

Function Get-MTGScryFallCards {
    [CmdletBinding()]
    param(
        [string]$SetName,
        [string]$APIUrl = "https://api.scryfall.com/cards/"
    )
    if($SetName) {
        $suffix = "search?q=e:$SetName"
    }
    $url = "$($APIUrl)/$suffix"; write-host $url
    [URI]$uri = New-Object System.Uri -ArgumentList $Url
    $set = Invoke-WebRequest -Uri $uri
    $hasmore = $true
    $cards = @();
    while($hasmore) {
        $Content = ConvertFrom-Json $set.Content
        foreach($card in $Content.data) {
            if($card.set -eq $setName) {
                $c = [Card]::new()
                if($card.card_faces) {
                    $c.Ctype = $card.layout
                    $c.Name = $card.card_faces[0].Name.Replace(',','##COMMA##')
                    $c.Cost = $card.card_faces[0].mana_cost
                    $c.Type = $card.card_faces[0].type_line
                    $c.Power = $card.card_faces[0].Power
                    $c.Toughness = $card.card_faces[0].Toughness
                    if($null -ne $card.card_faces[0].oracle_text) {
                        $c.Text = $card.card_faces[0].oracle_text.Replace("`n","<br>").Replace(",","##COMMA##")
                    }
                    else {
                        $c.Text = ""
                    }
                    $c.ConvertedManaCost = [int]$card.card_faces[0].cmc                
                    $colorIdentity = ""
                    try {
                        foreach($identity in $card.card_faces[0].colors) {
                            $ColorIdentity = $ColorIdentity + "{" + $identity + "}"
                        }
                    }   
                    catch {}
                    $c.ColorIdentity = $colorIdentity
                }
                else {
                    $c.Ctype = "mono"
                    $c.Name = $card.Name.Replace(",","##COMMA##")
                    $c.Cost = $card.mana_cost
                    $c.Type = $card.type_line
                    $c.Power = $card.Power
                    $c.Toughness = $card.Toughness
                    if($null -ne $card.oracle_text) {
                        $c.Text = $card.oracle_text.Replace("`n","<br>").Replace(",","##COMMA##")
                    }
                    else {
                        $c.Text = ""
                    }
                    $c.ConvertedManaCost = [int]$card.cmc
                    $colorIdentity = ""
                    try {
                        foreach($identity in $card.color_identity) {
                            $ColorIdentity = $ColorIdentity + "{" + $identity + "}"
                        }
                    }   
                    catch {}
                    $c.ColorIdentity = $colorIdentity
                }
                if($card.multiverse_ids) {
                    $c.ID = $card.multiverse_ids[0]
                    $c.ImageURL = "http://gatherer.wizards.com/Handlers/Image.ashx?multiverseid=$($c.ID)&type=card"
                }
                else {
                    if($card.mtgo_id) {
                        $c.ID = $card.mtgo_id
                    }
                    else {
                        $c.ID = $card.id
                    }
                    $c.ImageURL = $card.image_uris.large
                    
                }
                
                $c.Set = $card.Set_Name
                $c.Rarity = $card.Rarity.Replace("mythic", "Mythic Rare").Replace("common","Common").Replace("unCommon","Uncommon")

                $cards += $c
            }
            else {
                $hasmore = $false;
            }
        }
        if($Content.has_more) {
            $nexturl = "$($Content.next_page)&$suffix"
            write-verbose $nexturl
            [URI]$uri = New-Object System.Uri -ArgumentList $nexturl
            $set = Invoke-WebRequest -Uri $uri
        }
        else {
            $hasmore = $false
        }
    }
    if(Test-Path -Path ".\$SetName.csv") {
        Remove-Item -Path ".\$SetName.csv" -Force
    }
    "ID,NAME,COST,TYPE,POWER,TOUGHNESS,ORACLE,SET,RARITY,CTYPE,CMC,IMAGE_URL,COLOR_IDENTITY" | out-file -FilePath ".\$SetName.csv" -Append -NoClobber
    foreach($card in $cards) {
        $s = "$($card.ID),"
        $s = "$s$($card.Name),"
        $s = "$s$($card.Cost),"
        $s = "$s$($card.Type),"
        $s = "$s$($card.Power),"
        $s = "$s$($card.Toughness),"
        $s = "$s$($card.Text),"
        $s = "$s$($card.Set),"
        $s = "$s$($card.Rarity),"
        $s = "$s$($card.Ctype),"
        $s = "$s$($card.ConvertedManaCost),"
        $s = "$s$($card.ImageUrl),"
        $s = "$s$($card.ColorIdentity)"
        $s | out-file -FilePath ".\$SetName.csv" -Append -NoClobber
    }
    $cards
}

$setname = "a25"
Get-MTGScryFallCards -SetName $setname

#get the art
$csvFiles = Get-ChildItem -Path ".\" -Filter *.csv
foreach($file in $csvFiles) {
    $File = Get-Content $file.FullName
    $counter = 0
    foreach($line in $file) {
        if($counter -ne 0) {
            $props = $line.Split(",")
            $MultiVerseID = $props[0]
            $ImageUrl = $props[11]
            write-host "$MultiVerseID $ImageUrl"

            $localPath = ".\Media\$MultiVerseID.png"
            [Uri]$imgUri = New-Object System.Uri -ArgumentList $ImageUrl
            
            
            $file = Invoke-WebRequest -Uri $ImageUrl 
            if(-not (Test-Path $localPath)) {
                new-item -Path ".\Media" -Name "$MultiVerseID.png" -ItemType File -Force
            } 
            $file.Content | Set-Content -Path $localPath -Encoding Byte 
        }
        $counter++;
    }
}
