local version = 0.15
local Timer = Game.Timer
local Control = Control
local sqrt, abs = math.sqrt, math.abs
local MapID = Game.mapID


local wardItems = {
	["wrt"] = {name = "Warding Totem", 		id = 3340, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e2/Warding_Totem_item.png"},
	["eof"] = {name = "Eye of Frost", 		id = 3098, range = 600, icon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/26/Eye_of_Frost_item.png"},
}




local function GetDistance(A, B)
	local A = A.pos or A
	local B = B.pos or B

	local ABX, ABZ = A.x - B.x, A.z - B.z

	return sqrt(ABX * ABX + ABZ * ABZ)
end

local simpleAutoWard = setmetatable({}, {
	__call = function(self)
		self:__loadTables()
		self:__loadMenu()
		self:__loadCallbacks()
	end
})

	function simpleAutoWard:__loadMenu()
	
		self.menu = MenuElement({type = MENU, id = "simpleAutoWard", name = "Simple Auto Ward (Logic By Max)"})
				self.menu:MenuElement({id = "_e", name = "Enable Ward", value = true})
				self.menu:MenuElement({id = "_d", name = "Draw Spots", value = true})
				

	end

	function simpleAutoWard:__loadCallbacks()
		Callback.Add("Tick", function() self:__OnTick() end)
		Callback.Add("Draw", function() self:__OnDraw() end)
	end

	function simpleAutoWard:__loadTables()
		self.buffs = {}

		self.itemAmmoStorage = {
			[2031] = {maxStorage = 2, savedStorage = 0},
			[2032] = {maxStorage = 5, savedStorage = 0},
			[2033] = {maxStorage = 3, savedStorage = 0}
		}

		self.wards = {
			["preSpots"] = {
				{x = 10383, y = 50, z = 3081},
				{x = 11882, y = -70, z = 4121},
				{x = 9703, y = -32, z = 6338},
				{x = 8618, y = 52, z = 4768},
				{x = 5206, y = -46, z = 8511},
				{x = 3148, y = -66, z = 10814},
				{x = 4450, y = 56, z = 11803},
				{x = 6287, y = 54, z = 10150},
				{x = 8268, y = 49, z = 10225},
				{x = 11590, y = 51, z = 7115},
				{x = 10540, y = -62, z = 5117},
				{x = 4421, y = -67, z = 9703},
				{x = 2293, y = 52, z = 9723},
				{x = 7044, y = 54, z = 11352}
			}
		}

		
		self.itemKey = {
		}

	end


	function simpleAutoWard:__OnTick()
		if #self.itemKey == 0 then
			self.itemKey = {
				HK_ITEM_1,
				HK_ITEM_2,
				HK_ITEM_3,
				HK_ITEM_4,
				HK_ITEM_5,
				HK_ITEM_6,
				HK_ITEM_7
			}
		end

		if Game.IsOnTop and not myHero.dead then
			--Ward Stuff
			
				self:doWardLogic()
			
			
		end
	end

	function simpleAutoWard:__OnDraw()

			
				self:doWardDrawings()
			
			
		
	end

	function simpleAutoWard:__getSlot(id)
		for i = 6, 12 do
			if myHero:GetItemData(i).itemID == id then
				return i
			end
		end

		return nil
	end

	function simpleAutoWard:itemReady(id, ward, pot)
		local slot = self:__getSlot(id)

		if slot then
			local cd = myHero:GetSpellData(slot).currentCd == 0

			if cd then
				if ward then
					local wardNum = id == 3340 and myHero:GetSpellData(slot).ammo or myHero:GetItemData(slot).stacks --id ~= 2057 and myHero:GetSpellData(slot).ammo or 

					return wardNum ~= 0 and wardNum < 10
				else
					return true
				end
			end
		end

		return false
	end

	
	function simpleAutoWard:castItem(unit, id, range, checked)
		if checked or unit == myHero or GetDistance(myHero, unit) <= range then
			local keyIndex = self:__getSlot(id) - 5
			local key = self.itemKey[keyIndex]

			if key then
				if unit ~= myHero then
					Control.CastSpell(key, unit.pos or unit)
				else
					Control.CastSpell(key, myHero)
				end
			end
		end
	end

--==================== WARD MODULE ====================--
	function simpleAutoWard:doWardLogic()

		if not (self.lastWard and Timer() - self.lastWard < 2) then 
			for short, data in pairs(wardItems) do
				if self:itemReady(data.id, true) then
					for i = 1, #self.wards.preSpots do
						local ward = Vector(self.wards.preSpots[i])

						if ward:To2D().onScreen and GetDistance(ward, (myHero or mousePos)) <= (data.range or 100) then
							local c, d = self:getNearesetWardToPos(ward)

							if not (c and d < 600) then
								self.lastWard = Timer()
								self:castItem(ward, data.id, data.range, true)
								return
							end
						end
					end
				end
			end
		end
	end

	function simpleAutoWard:doWardDrawings()
		for i = 1, #self.wards.preSpots do
			local wardSpot = Vector(self.wards.preSpots[i]):To2D()

			if wardSpot.onScreen then
				Draw.Text("Ward Spot", 10, wardSpot.x, wardSpot.y)
			end
		end
	end

	function simpleAutoWard:getNearesetWardToPos(pos)
		local closest, distance = nil, 999999

		for i = 1, Game.WardCount() do
			local ward = Game.Ward(i)

			if ward.team == myHero.team then
				local d = GetDistance(ward, pos) 

				if d < distance then
					distance = d
					closest = ward
				end
			end
		end

		return closest, distance
	end


simpleAutoWard()

