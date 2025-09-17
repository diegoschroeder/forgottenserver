local event = Event()
local AUTOLOOT_STORAGE = 15002 -- Storage para ativação do autoloot
local AUTOLOOT_LIST_START_KEY = 16001 -- Storage inicial da lista de itens permitidos
local AUTOLOOT_LIST_MAX = 100 -- Máximo de itens na lista

event.onDropLoot = function(self, corpse)
	if configManager.getNumber(configKeys.RATE_LOOT) == 0 then
		return
	end

	local player = Player(corpse:getCorpseOwner())
	local mType = self:getType()
	local doCreateLoot = false

	if not player or player:getStamina() > 840 or not configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		doCreateLoot = true
	end

	if doCreateLoot then
		local monsterLoot = mType:getLoot()
		for i = 1, #monsterLoot do
			local item = corpse:createLootItem(monsterLoot[i])
			if not item then
				print("[Warning] DropLoot: Could not add loot item to corpse.")
			end
		end
	end

	if player then
		-- Verifica autoloot customizado
		if player:getStorageValue(AUTOLOOT_STORAGE) == 1 then
			local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
			if backpack then
						-- Percorre do último para o primeiro para evitar problemas ao remover itens
						for i = corpse:getSize(), 1, -1 do
							local lootItem = corpse:getItem(i - 1)
							if lootItem then
								local allow = false
								local itemId = lootItem:getId()
								for idx = 0, AUTOLOOT_LIST_MAX - 1 do
									local storageKey = AUTOLOOT_LIST_START_KEY + idx
									if player:getStorageValue(storageKey) == itemId then
										allow = true
										break
									end
								end
								if allow then
									if backpack:addItemEx(lootItem) == RETURNVALUE_NOERROR then
										corpse:removeItem(lootItem)
										-- Item transferido com sucesso
									end
									-- Se não couber, mantém no corpo normalmente
								end
								-- Se não estiver na lista, permanece no corpo normalmente
							end
						end
			end
		end
		local text
		if doCreateLoot then
			text = ("Loot of %s: %s."):format(mType:getNameDescription(), corpse:getContentDescription())
		else
			text = ("Loot of %s: nothing (due to low stamina)."):format(mType:getNameDescription())
		end
		local party = player:getParty()
		if party then
			party:broadcastPartyLoot(text)
		else
			player:sendTextMessage(MESSAGE_LOOT, text)
		end
	end
end

event:register()
