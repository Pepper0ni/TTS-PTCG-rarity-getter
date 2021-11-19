function onLoad()
 local selfScale=self.getScale()
 local params={
 function_owner=self,
 label='Get Rarities',
 tooltip="Logs set rarities in notes",
 font_size=180,
 width=1500,
 height=220,
 scale={1/selfScale.x,1/selfScale.y,1/selfScale.z},
 position={0,0,1},
 click_function='GetRarities'
 }
 self.createButton(params)
 
 params.position[3]=2
 params.label='Reset Loading'
 params.tooltip="Resets the loading var if it crashes"
 params.click_function='resetLoad'
 self.createButton(params)

 params.position[3]=1.5
 params.tooltip="The set name to search"
 params.label='Enter Set Name'
 params.alignment=3
 params.input_function="dummyFunc"
 params.font_color={0,0,0}
 self.createInput(params)
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
   r[c]=WebRequest.get('https://api.pokemontcg.io/v2/cards?q=!set.name:"'..string.gsub(self.getInputs()[1].value,"&","%%26")..'"&page='..tostring(c)..'&pageSize='..tostring(300/pageSize).."&orderBy=number", function() handleRarities(r[c],color,c,pageSize)end)
  end
 end
end

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
   if rarityTable[cardData.rarity] then
    table.insert(rarityTable[cardData.rarity],c+basePage)
   else
    rarityTable[cardData.rarity]={c+basePage}
   end
  end
  if loadVar==1 then
   local outputStr=""
   for rarity,cards in pairs(rarityTable) do
    outputStr=outputStr..rarity.."={"..table.concat(cards,",").."}\n"
   end
   Notes.setNotes(outputStr)
  end
  Global.SetVar("PPacksRarityLoading",loadVar-1)
 end
end

function dummyFunc()
end

function resetLoad()
 Global.SetVar("PPacksRarityLoading",0)
end
