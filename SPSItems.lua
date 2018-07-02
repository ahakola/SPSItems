local ADDON_NAME = ...
local db
local lastTime = 0
local turnInItems = { -- Quests and Quest items
	-- Creature-0-1587-1116-1-87393-000051A07C
	[35147] = 118099, -- Fragments of the Past -> 20 x Gorian Artifact Fragment
	[37125] = 118100, -- A Rare Find -> Highmaul Relic
	-- Creature-0-1587-1116-1-87706-000051A07C	
	[37210] = 118654, -- Aogexon's Fang
	[37211] = 118655, -- Bergruu's Horn
	[37221] = 118656, -- Dekorhan's Tusk
	[37222] = 118657, -- Direhoof's Hide
	[37223] = 118658, -- Gagrog's Skull
	[37224] = 118659, -- Mu'gra's Head
	[37225] = 118660, -- Thek'talon's Talon
	[37226] = 118661, -- Xelganak's Stinger
	[37520] = 120172, -- Vileclaw's Claw
}

local LOCALE = GetLocale()
local L = {}
L.RemainingTurnins = "Remaining turn-ins:"
L.DBQuestNotFound = "DB of localized quests is incomplete, automation won't work for every item. This will be self-fixed with future logins"
L.TurningIn = "Turning in"
if LOCALE == "deDE" then
--@localization(locale="deDE", format="lua_additive_table")@
elseif strmatch(LOCALE, "^es") then
--@localization(locale="esES", format="lua_additive_table")@
elseif LOCALE == "frFR" then
--@localization(locale="frFR", format="lua_additive_table")@
elseif LOCALE == "itIT" then
--@localization(locale="itIT", format="lua_additive_table")@
elseif LOCALE == "ptBR" then
--@localization(locale="ptBR", format="lua_additive_table")@
elseif LOCALE == "ruRU" then
--@localization(locale="ruRU", format="lua_additive_table")@
elseif LOCALE == "koKR" then
--@localization(locale="koKR", format="lua_additive_table")@
elseif LOCALE == "zhCN" then
--@localization(locale="zhCN", format="lua_additive_table")@
elseif LOCALE == "zhTW" then
--@localization(locale="zhTW", format="lua_additive_table")@
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

local MyScanningTooltip = CreateFrame("GameTooltip", "MyScanningTooltip", UIParent, "GameTooltipTemplate")

function f:Print(text, ...)
	if text then
		if text:match("%%[dfqs%d%.]") then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00".. ADDON_NAME ..":|r " .. format(text, ...))
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00".. ADDON_NAME ..":|r " .. strjoin(" ", text, tostringall(...)))
		end
	end
end

function f:GetItemName(id) -- Returns items name from db if available, if not try to get it from server
	if db.items[id] and db.items[id] ~= nil then
		return db.items[id]
	else
		local name = GetItemInfo(id)

		if name then
			db.items[id] = name
			return name
		end

		return nil
	end
end

function f:GetQuestTitleFromID(id) -- http://www.wowinterface.com/forums/showpost.php?p=281552&postcount=4
	if db.quests[id] and db.quests[id] ~= nil then
		return db.quests[id]
	else
		MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
		MyScanningTooltip:SetHyperlink("quest:"..id)
		local title = MyScanningTooltipTextLeft1:GetText()
		MyScanningTooltip:Hide()

		if title and title ~= RETRIEVING_DATA then
			db.quests[id] = title
			return title
		end

		return nil
	end
end

function f:GetGUID() -- Returns npcID of target
	local guid = UnitGUID("target")
	if not guid then return end
	local unitType, _, _, _, _, npcID, _ = strsplit("-", guid);

	if npcID and unitType == "Creature" then
		return tonumber(npcID)
	else
		return nil
	end
end

function f:ParseQuests(...)  -- Return quest names from all available gossip quest data
	local t = {}
	
	for i = 1, select("#", ...), 6 do
		-- title, level, isTrivial, frequency, isRepeatable, isLegendary
		local questName = select(i, ...)

		table.insert(t, questName)
	end

	return t
end

function f:IterateQuests() -- Get all available gossip quests and decide if we can turn them in
	local availableQuests = self:ParseQuests(GetGossipAvailableQuests())

	for i = 1, #availableQuests do
		if not availableQuests[i] or availableQuests[i] == nil then return end -- Just to be safe

		for questID, itemID in pairs(turnInItems) do
			if self:GetGUID() == 87393 then
				local _, _ = self:GetQuestTitleFromID(35147), self:GetQuestTitleFromID(37125)

				if itemID == 118099 and GetItemCount(itemID) >= 20 and self:GetQuestTitleFromID(questID) == availableQuests[i] then
					self:RegisterEvent("QUEST_PROGRESS")
					self:RegisterEvent("QUEST_COMPLETE")

					SelectGossipAvailableQuest(i)
					return
				elseif itemID ~= 118099 and GetItemCount(itemID) >= 1 and self:GetQuestTitleFromID(questID) == availableQuests[i] then
					self:RegisterEvent("QUEST_PROGRESS")
					self:RegisterEvent("QUEST_COMPLETE")

					SelectGossipAvailableQuest(i)
					return
				end
			else
				if GetItemCount(itemID) >= 1 and self:GetItemName(itemID) == availableQuests[i] then
					self:RegisterEvent("QUEST_PROGRESS")
					self:RegisterEvent("QUEST_COMPLETE")

					SelectGossipAvailableQuest(i)
					return
				end
			end
		end
	end

	self:CountItems()
end

function f:CountItems(fromSlash) -- Count remaining items to turn in
	if not fromSlash and GetTime() - 2 < lastTime then return end -- Don't spam this, unless it came from Slash or quest completed

	local count = 0
	for _, itemID in pairs(turnInItems) do
		if itemID == 118099 then
			count = count + floor(GetItemCount(itemID)/20)
		else
			count = count + GetItemCount(itemID)
		end
	end

	self:Print(L.RemainingTurnins, count)

	if not fromSlash and count == 0 then -- Pass the Spam-Brake if there are turn-ins remaining
		lastTime = GetTime()
	else
		lastTime = 0
	end
end

f:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, event, ...)
end)

function f:ADDON_LOADED(_, addon)
	if addon ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")

	if type(SPSItemsData) ~= "table" then SPSItemsData = {} end
	if type(SPSItemsData.items) ~= "table" then SPSItemsData.items = {} end
	if type(SPSItemsData.quests) ~= "table" then SPSItemsData.quests = {} end
	db = SPSItemsData

	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self:RegisterEvent("PLAYER_LOGIN")
	end

	self.ADDON_LOADED = nil
end

function f:PLAYER_LOGIN()
	self:UnregisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("QUEST_LOG_UPDATE") -- Cache quest data when server isn't busy returning existing quests data

	self.PLAYER_LOGIN = nil
end

function f:GOSSIP_SHOW()
	if not GossipFrame:IsVisible() then return end

	if GetNumGossipAvailableQuests() > 0 and (self:GetGUID() == 87393 or self:GetGUID() == 87706) then
		if not (db.quests[35147] and db.quests[37125]) then -- Warn for uncached quests
			self:Print(L.DBQuestNotFound)

			local _, _ = self:GetQuestTitleFromID(35147), self:GetQuestTitleFromID(37125)
		end

		self:IterateQuests()
	end
end

function f:QUEST_LOG_UPDATE()
	self:UnregisterEvent("QUEST_LOG_UPDATE")

	for _, itemID in pairs(turnInItems) do -- Try to save these localy so they are always available
		local _ = self:GetItemName(itemID)
		_ = self:GetQuestTitleFromID(35147)
		_ = self:GetQuestTitleFromID(37125)
	end

	self.QUEST_LOG_UPDATE = nil
end

function f:QUEST_PROGRESS()
	if not QuestFrame:IsVisible() then return end

	self:UnregisterEvent("QUEST_PROGRESS")

	if IsQuestCompletable() then
		CompleteQuest()
	else
		QuestDetailDeclineButton_OnClick()
	end
end

function f:QUEST_COMPLETE()
	if not QuestFrame:IsVisible() then return end

	self:UnregisterEvent("QUEST_COMPLETE")
	self:Print(L.TurningIn, GetTitleText())

	if not (GetNumQuestChoices() > 1) then
		GetQuestReward(1)
	end

	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
end

do -- BAG_UPDATE throttling
	local throttling

	local function DelayedUpdate()
		throttling = nil
		f:UnregisterEvent("BAG_UPDATE")
		f:UnregisterEvent("BAG_UPDATE_DELAYED")
		f:CountItems(true)
	end

	local function ThrottleUpdate()
		if not throttling then
			throttling = true
			C_Timer.After(0.5, DelayedUpdate)
		end
	end

	f.BAG_UPDATE = ThrottleUpdate
	f.BAG_UPDATE_DELAYED = ThrottleUpdate
end

SLASH_SPSITEMS1 = "/sps"
SLASH_SPSITEMS2 = "/spsitems"

SlashCmdList.SPSITEMS = function(arg)
	f:CountItems(true)
end