function onLoad()
 local selfScale=self.getScale()
 local params={
 function_owner=self,
 font_size=180,
 width=1500,
 height=220,
 scale={1/selfScale.x,1/selfScale.y,1/selfScale.z},
 }
 butWrapper(params,{0,0,1},'Get Rarities',"Logs set rarities in notes",'GetRarities')
 butWrapper(params,{0,0,2},'Reset Loading',"Resets the loading var if it crashes",'resetLoad')

 params.position={0,0,1.5}
 params.tooltip="The set ID to search"
 params.label='Enter Set ID'
 params.alignment=3
 params.input_function="processReturn"
 params.font_color={0,0,0}
 self.createInput(params)
end

function butWrapper(params,pos,label,tool,func)
 params.position=pos
 params.label=label
 params.tooltip=tool
 params.click_function=func
 self.createButton(params)
end

rarityTable={}

function GetRarities(obj,color,alt)
 local settings=Global.GetTable("PPacks")
 local pageSize=tonumber(settings.APICalls)or 3
 local loading=Global.GetVar("PPacksRarityLoading")
 rarityTable={}
 if not loading or loading==0 then
  Global.SetVar("PPacksRarityLoading",pageSize)
  r={}
  for c=1,pageSize do
   r[c]=WebRequest.get('https://api.pokemontcg.io/v2/cards?q=!set.id:"'..self.getInputs()[1].value..'"&page='..tostring(c)..'&pageSize='..tostring(300/pageSize).."&orderBy=number", function() handleRarities(r[c],color,c,pageSize)end)
  end
 end
end

reverseRarities={Common=true,Uncommon=true,Rare=true,["Rare Holo"]=true}

function handleRarities(request,color,page,pageSize)
 local loadVar=Global.GetVar("PPacksRarityLoading")
 if request.is_error or request.response_code>=400 then
  log(request.error)
  log(request.text)
  broadcastToColor("Error: "..tostring(request.response_code),color,{1,0,0})
  Global.SetVar("PPacksRarityLoading",0)
 elseif loadVar>=1 then
  local decoded=json.parse(string.gsub(request.text,"\\u0026","&"))
--credit to dzikakulka and Larikk 
--use the below line in the parse instead if this line of code ever breaks
--string.gsub(request.text,[[\u([0-9a-fA-F]+)]],function(s)return([[\u{%s}]]):format(s)end)
  local basePage=(page-1)*(300/pageSize)
  for c,cardData in ipairs(decoded.data)do
   if not (string.match(cardData.number,"^%d")and string.match(cardData.number,"%l$"))then
    if rarityTable[cardData.rarity] then
     table.insert(rarityTable[cardData.rarity],c+basePage)
    else
     rarityTable[cardData.rarity]={c+basePage}
    end
    if reverseRarities[cardData.rarity]then
     if rarityTable["Reverse Holo"] then
      table.insert(rarityTable["Reverse Holo"],c+basePage)
     else
      rarityTable["Reverse Holo"]={c+basePage}
     end
    end
   end
  end
  if loadVar==1 then
   local outputStr=""
   for rarity,cards in pairs(rarityTable)do
    table.sort(cards)
    local lastnum=-1
    local chain=-1
    local cardsStr="={"
    for c,card in pairs(cards)do
     if chain==-1 or card==lastnum+1 then
      chain=chain+1
      lastnum=card
     else
      cardsStr=finishChain(chain,lastnum,cardsStr,true)
      chain=0
      lastnum=card
     end
    end
    cardsStr=finishChain(chain,lastnum,cardsStr,false)
    outputStr=outputStr..rarity..cardsStr.."},size="..tostring(#cards).."\n"
   end
   Notes.setNotes(outputStr)
  end
  Global.SetVar("PPacksRarityLoading",loadVar-1)
 end
end

function finishChain(chain,lastnum,str,comma)
 local commatext=""
 if comma then commatext=","end
 if chain==0 then
  return str..tostring(lastnum)..commatext
 elseif chain==1 then
  return str..tostring(lastnum-1)..","..tostring(lastnum)..commatext
 else
  return str.."{"..tostring(lastnum-chain)..","..tostring(lastnum).."}"..commatext
 end
end

function processReturn(obj,color,value,selected)
 local subedValue=string.gsub(value,"\n","")
 if subedValue!=value then
  Wait.frames(function()GetRarities(obj,color,false) end,1)
 end
 return subedValue
end

function resetLoad()
 Global.SetVar("PPacksRarityLoading",0)
end
