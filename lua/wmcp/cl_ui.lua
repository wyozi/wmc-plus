function wmcp.OpenUI()
	local fr = vgui.Create("DFrame")
	fr:SetSkin("WMCPUI")
	fr:SetTitle("Wyozi Media Center Plus")
	fr:SetSizable(true)

	fr:ShowCloseButton(false)

	fr:SetSize(900, 600)
	fr:Center()

	-- Close button
	do
		local btn = fr:Add("DButton")
		btn:SetText("")
		btn.BGTint = Color(210, 77, 87)
		btn.OutlineTint = Color(255, 255, 255, 80)
		function btn:PerformLayout()
			btn:SetPos(fr:GetWide() - 29, 3)
			btn:SetSize(25, 19)
		end
		function btn:PaintOver(w, h)
			surface.SetDrawColor(255, 255, 255, 180)
			surface.DrawRect(4, h - 7, w - 8, 3)
		end
		btn.DoClick = function() fr:Close() end
	end

	wmcp.CreateMediaList(fr)
	wmcp.CreatePlayer(fr)

	fr:MakePopup()

	wmcp.Frame = fr

	hook.Call("WMCPPostOpenUI", nil, fr)

	fr.OnClose = function()
		hook.Call("WMCPPreCloseUI", nil, fr)
	end
end

function wmcp.IsOpen()
	return IsValid(wmcp.Frame) and wmcp.Frame:IsVisible()
end

function wmcp.CloseUI()
	if not IsValid(wmcp.Frame) then return end

	wmcp.Frame:Close()
end

concommand.Add("wmcp", function()
	if wmcp.IsOpen() then
		wmcp.CloseUI()
	else
		wmcp.OpenUI()
	end
end)

local function makeSortingNames(par)
	for k, v in ipairs(par.Columns) do
		local name = v.Header:GetText()
		local changed = false

		local up   = "/\\ " --"↑ "
		local down = "\\/ " --"↓ "

		-- This assumes the variables 'up' and 'down' have the same number
		-- of bytes in the string. It also assumes that the 'up' or 'down'
		-- string can be find at the very beginning of the variable 'name'.
		-- You wouldn't break these assumptions...would you?
		if name:find(up, 1, true) or name:find(down, 1, true) then
			name = name:sub(up:len() + 1)
			changed = true
		end

		if k == par.sortColumn then
			name = (par.sortDescending and down or up) .. name
			changed = true
		end

		if changed then
			v:SetName(name)
		end
	end
end

local function columnDoClick(self)
	local myID = self:GetColumnID()
	local par = self:GetParent()

	if par.sortColumn == myID then
		par.sortDescending = not par.sortDescending
	else
		par.sortColumn = myID
		par.sortDescending = true
	end

	makeSortingNames(par)
	par:DataLayout()
end

local t = nettable.get("WMCPMedia.Main")

function wmcp.CreateMediaList(par)
	local medialist = par:Add("DListView")
	medialist:SetHeaderHeight(22)
	medialist:SetDataHeight(22)
	medialist:SetMultiSelect(false)
	medialist:Dock(FILL)

	local columnDate = medialist:AddColumn("\\/ Date")--("↓ Date")
	local columnTitle = medialist:AddColumn("Title")
	local columnAddedBy = medialist:AddColumn("Added by")

	columnDate:SetFixedWidth(100)
	columnAddedBy:SetFixedWidth(150)

	columnDate.DoClick = columnDoClick
	columnTitle.DoClick = columnDoClick
	columnAddedBy.DoClick = columnDoClick

	medialist.sortColumn = 1 -- sort by date
	medialist.sortDescending = true -- sort in descending order by default

	-- Hack DataLayout to sort items before doing whatever DataLayout does
	local olddl = medialist.DataLayout
	medialist.DataLayout = function(self)
		table.Copy(self.Sorted, self.Lines)

		table.sort(self.Sorted, function(a, b)
			-- Return 'true' if 'a' should move up.

			-- Grab the dates to check for the add-video button.
			local atext = a:GetColumnText(1)
			local btext = b:GetColumnText(1)

			-- The date column of the add-video button is "".
			-- So we just keep it moving down to the bottom.
			if atext == "" then return false end
			if btext == "" then return true end

			local column = self.sortColumn
			local descending = self.sortDescending

			-- Sorting by the 'Title' or 'Added by' column.
			if column ~= 1 then
				atext = a:GetColumnText(column)
				btext = b:GetColumnText(column)

				if column == 3 then
					-- :GetColumnText on the "Added by" column returns a
					--  "WMCPlayerCell" panel.
					atext = atext.NickLabel:GetText()
					btext = btext.NickLabel:GetText()
				end
			end

			if descending then
				return atext < btext
			else
				return atext > btext
			end
		end)

		return olddl(self)
	end

	-- Add "add new video" entry as the last row.
	do
		local adder = vgui.Create("DButton")
		adder.BGTint = Color(145, 61, 136)
		adder:SetSkin("WMCPUI")
		adder:SetText("Add new video by clicking here")
		adder.DoClick = function()
			Derma_StringRequest("Video adder", "Please input an URL", "", function(url)
				RunConsoleCommand("wmcp_add", url)
			end)
		end
		local line = medialist:AddLine("", adder, nil)
		function line:DataLayout(listView)
			self:ApplySchemeSettings()

			local margin = 0
			self.Columns[2]:SetPos(margin, 0)
			self.Columns[2]:SetSize(self:GetWide() - margin*2, self:GetTall())
		end
	end

	local function Play(url)
		local media = t[url]

		if not media then
			chat.AddText("invalid media")
			return
		end

		local clip = wmcp.Play(url, {title = media.title})

		if clip then
			clip:on("ended", function(info)
				if info and info.stopped then
					return
				end

				-- Play the media in the next line.
				-- Will have problems if the playing media is deleted.
				timer.Simple(0.5, function()
					local isnext = false
					for k, line in ipairs(medialist.Sorted) do
						-- a nice little bird-nest here
						if isnext then
							Play(line.url)
							return
						end

						if line.url == url then
							isnext = true
						end
					end
				end)
			end)
		end
	end

	function medialist:DoDoubleClick(id, line)
		if line.url then
			Play(line.url)
		end
	end

	function medialist:OnRowRightClick(id, line)
		if not line.url then return end

		local menu = DermaMenu()

		menu:AddOption("Play", function()
			Play(line.url)
		end):SetImage("icon16/control_play.png")

		if ULib then
			local button = menu:AddOption("Play for Everyone", function()
				RunConsoleCommand("ulx", "gplay", line.url, line:GetColumnText(2))
			end)

			button:SetImage("icon16/control_play_blue.png")

			if not ULib.ucl.query(LocalPlayer(), "ulx gplay", true) then
				button:SetDisabled(true)
				button:SetColor(Color(0, 166, 147)) -- lighten the text color
			end
		else
			menu:AddOption("Play for Everyone", function()
				RunConsoleCommand("wmcp_play", line.url, line:GetColumnText(2))
			end):SetImage("icon16/control_play_blue.png")
		end

		menu:AddSpacer()

		menu:AddOption("Copy URL", function()
			SetClipboardText(line.url)
		end):SetImage("icon16/paste_plain.png")

		menu:AddSpacer()

		menu:AddOption("Set title", function()
			local title = line:GetColumnText(2)
			Derma_StringRequest("WMCP: Set title", "Set title of '" .. title .. "'", title, function(newTitle)
				RunConsoleCommand("wmcp_settitle", line.url, newTitle)
			end)
		end):SetImage("icon16/monitor_edit.png")

		menu:AddOption("Delete", function()
			RunConsoleCommand("wmcp_del", line.url)
		end):SetImage("icon16/monitor_delete.png")

		-- Parameters:
		--   menu    - a DMenu
		--   line    - a DListView_Line (see the function ModLine)
		--   url     - a string with the media's URL
		--   media   - a table with the following keys: title, a_sid, a_nick
		hook.Call("WMCPMedialistRowRightClick", nil, menu, line, line.url, t[line.url])

		menu:Open()
	end

	local function ModLine(url, media)
		local line

		for _, v in ipairs(medialist.Lines) do
			if v.url == url then
				line = v
				break
			end
		end

		if not line then
			line = medialist:AddLine(os.date("%c", media.date))
			line:SetCursor("hand")

			line.ActiveCond = function(self)
				local clip = wmcp.GetClip()
				return clip and clip:getUrl() == self.url
			end

			line.url = url
		end

		if media.title then
			line:SetColumnText(2, media.title):SetFont("WMCPUINormalFont")
		end

		if media.a_sid and media.a_nick then
			local plrcell = line:Add("WMCPlayerCell")
			plrcell.NickLabel:SetFont("WMCPUINormalFont")
			plrcell:SetSIDNick(media.a_sid, media.a_nick)
			line:SetColumnText(3, plrcell)
		end
	end

	for url, media in pairs(t) do
		ModLine(url, media)
	end

	nettable.setChangeListener(t, "UIUpdater", function(e)
		if not IsValid(medialist) then return end

		for url, media in pairs(e.modified) do
			ModLine(url, media)
		end

		-- Loops through checking if a media table was deleted.
		-- If so, then remove the line from the medialist.
		for url, v in pairs(e.deleted) do
			-- Skip if the media table itself isn't being deleted.
			if v ~= true then continue end

			for _, line in pairs(medialist.Lines) do
				if line.url == url then
					local lineID = line:GetID()

					if lineID then
						medialist:RemoveLine(lineID)
					end

					break
				end
			end
		end
	end)

	return medialist
end

surface.CreateFont("WMCPMediaTitle", {
	font = "Roboto",
	size = 22
})

function wmcp.CreatePlayer(par)
	local player = par:Add("DPanel")
	par.Player = player

	player:Dock(BOTTOM)
	player:SetTall(50)

	player.Seeker = player:Add("WMCMediaSeeker")
	player.Seeker.SeekerBG = Color(34, 49, 63)
	player.Seeker.OnSeeked = function(_, frac)
		local clip = wmcp.GetClip()
		local meta = wmcp.GetClipMeta()
		if IsValid(clip) and meta and meta.duration then
			clip:seek(meta.duration * frac)
		end
	end

	player.VolSeekerIcon = player:Add("DImage")
	player.VolSeekerIcon:SetImage("icon16/sound.png")
	player.VolSeekerIcon:SetSize(16, 16)

	player.VolSeeker = player:Add("WMCMediaSeeker")
	player.VolSeeker:SetDuration(100)
	player.VolSeeker:SetElapsed(wmcp.GetVolume()*100)
	player.VolSeeker.SeekerBG = Color(68, 108, 179)
	player.VolSeeker.OnSeeking = function(pself, frac)
		pself:SetElapsed(frac * 100)
		wmcp.SetVolume(frac)
	end
	player.VolSeeker.OnSeeked = player.VolSeeker.OnSeeking

	player.Title = player:Add("DLabel")
	player.Title:SetFont("WMCPMediaTitle")
	player.Title:SetText("")

	player.Play = player:Add("DButton")
	player.Play.BGTint = Color(30, 130, 76)
	player.Play:SetText("Play")
	player.Play.DoClick = function()
		wmcp.TogglePlay()
	end

	function player:Think()
		local clip = wmcp.GetClip()

		if IsValid(clip) and clip:isPlaying() then
			player.Play:SetText("Pause")
		else
			player.Play:SetText("Play")
		end

		local meta = wmcp.GetClipMeta()

		if meta and meta.title then
			player.Title:SetText(meta.title)
		end

		if IsValid(clip) then
			player.Seeker:SetElapsed(clip:getTime())
		end

		if meta and meta.duration then
			player.Seeker:SetDuration(meta.duration)
		end
	end

	function player:PerformLayout()
		local mid = self:GetWide() / 2
		self.Play:SetPos(5, 22)
		self.Play:SetSize(100, 25)

		self.Title:SetPos(115, 22)
		self.Title:SetSize(self:GetWide() - 210, 26)

		self.Seeker:SetPos(5, 4)
		self.Seeker:SetSize(self:GetWide() - 10, 16)

		self.VolSeekerIcon:SetPos(self:GetWide() - 145, 26)
		self.VolSeeker:SetPos(self:GetWide() - 125, 24)
		self.VolSeeker:SetSize(120, 22)
	end
end
