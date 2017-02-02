local config = {
	{
		cvar = "wmcp_debugvideo",

		text = function(cvarValue) return cvarValue == "1" and "Disable video" or "Enable video" end,
		icon = function(cvarValue) return cvarValue == "1" and "icon16/film_add.png" or "icon16/film_delete.png" end,

		onPress = function(prevCvarValue) return prevCvarValue == "1" and "0" or 1 end
	},
	{
		cvar = "wmcp_unfocusedmute",

		text = function(cvarValue) return cvarValue == "1" and "Play sound when unfocused" or "Mute sound when unfocused" end,
		icon = function(cvarValue) return cvarValue == "1" and "icon16/sound_delete.png" or "icon16/sound_add.png" end,

		onPress = function(prevCvarValue) return prevCvarValue == "1" and "0" or 1 end
	}
}

function wmcp.OpenUI()
	local fr = vgui.Create("DFrame")
	fr:SetSkin("WMCPUI")
	fr:SetTitle("Wyozi Media Center Plus")
	fr:SetSizable(true)

	fr:ShowCloseButton(false)

	fr:SetSize(900, 600)
	fr:Center()

	local closeButton
	do
		local btn = fr:Add("DButton")
		closeButton = btn

		btn:SetText("")
		btn.BGTint = Color(210, 77, 87)
		btn.OutlineTint = Color(255, 255, 255, 80)
		function btn:PaintOver(w, h)
			surface.SetDrawColor(255, 255, 255, 180)
			surface.DrawRect(4, h - 7, w - 8, 3)
		end
		btn.DoClick = function() fr:Close() end
	end

	local configButton
	do
		local btn = fr:Add("DButton")
		configButton = btn

		btn:SetText("")
		btn.BGTint = Color(110, 135, 135)
		btn.OutlineTint = Color(255, 255, 255, 80)

		local cog = Material("icon16/cog.png")
		function btn:PaintOver(w, h)
			surface.SetDrawColor(255, 255, 255, 180)
			surface.SetMaterial(cog)
			surface.DrawTexturedRect(5, 2, 16, 16)
		end
		btn.DoClick = function()
			local menu = DermaMenu()

			for _,cfg in pairs(config) do
				local cvar = GetConVar(cfg.cvar)
				local value = cvar:GetString()

				menu:AddOption(cfg.text(value), function()
					cvar:SetString(cfg.onPress(value))
				end):SetIcon(cfg.icon(value))

			end

			menu:Open()
		end
	end

	wmcp.CreateMediaList(fr)
	wmcp.CreatePlayer(fr)

	function fr:PerformLayout()
		closeButton:SetPos(self:GetWide() - 29, 3)
		closeButton:SetSize(25, 19)

		configButton:SetPos(self:GetWide() - 57, 3)
		configButton:SetSize(25, 19)
	end

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
	wmcp.OpenUI()
end)

local t = nettable.get("WMCPMedia.Main")
function wmcp.CreateMediaList(par)
	local medialist = par:Add("DListView")
	medialist:SetHeaderHeight(22)
	medialist:SetDataHeight(22)
	medialist:SetMultiSelect(false)
	medialist:Dock(FILL)
	medialist:AddColumn("ID")
	medialist:AddColumn("Title")
	medialist:AddColumn("Added by")
	medialist.Columns[1]:SetFixedWidth(29)
	medialist.Columns[3]:SetFixedWidth(150)

	-- Remove sorting by removing DButton functionality. This retains WMCPUI skin
	for _,v in pairs(medialist.Columns) do v.Header:SetDisabled(true) v.DoClick = function() end end

	-- Hack DataLayout to sort items before doing whatever DataLayout does
	local olddl = medialist.DataLayout
	medialist.DataLayout = function(self)
		table.Copy(self.Sorted, self.Lines)
		table.sort(self.Sorted, function(a, b)
			local aval = tonumber(a:GetColumnText(1))
			local bval = tonumber(b:GetColumnText(1))
			if not aval then return false end
			if not bval then return true end
			return  aval < bval
		end)

		return olddl(self)
	end

	-- Add "add new video" entry as the last row
	do
		local adder = vgui.Create("DButton")
		adder.BGTint = Color(145, 61, 136)
		adder:SetSkin("WMCPUI")
		adder:SetText("Add new video by clicking here")
		adder.DoClick = function()
			wmcp.OpenVideoSelector(function(url, act)
				if act == "add" then
					RunConsoleCommand("wmcp_add", url)
				elseif act == "play" then
					wmcp.Play(url)
				end
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

	local function Play(mid)
		local e = t[mid]

		if not e then return end

		local clip = wmcp.Play(e.url, {title = e.title})
		if clip then
			clip:on("ended", function(info)
				if not info or not info.stopped then
					timer.Simple(0.5, function()
						Play(mid+1)
					end)
				end
			end)
		end
	end

	function medialist:DoDoubleClick(id, line)
		if not line.MediaId then return end
		Play(line.MediaId)
	end

	function medialist:OnRowRightClick(id, line)
		if not line.MediaId then return end

		local menu = DermaMenu()

		menu:AddOption("Play", function()
			Play(line.MediaId)
		end):SetImage("icon16/control_play.png")

		menu:AddOption("Play for Everyone", function()
			RunConsoleCommand("wmcp_gplay", line.Url, line:GetColumnText(2))
		end):SetImage("icon16/control_play_blue.png")

		menu:AddSpacer()

		menu:AddOption("Copy URL", function()
			SetClipboardText(line.Url)
		end):SetImage("icon16/paste_plain.png")

		menu:AddSpacer()

		menu:AddOption("Set title", function()
			local title = line:GetColumnText(2)
			Derma_StringRequest("WMCP: Set title", "Set title of '" .. title .. "'", title, function(newTitle)
				RunConsoleCommand("wmcp_settitle", line.MediaId, newTitle)
			end)
		end):SetImage("icon16/monitor_edit.png")

		menu:AddOption("Delete", function()
			RunConsoleCommand("wmcp_del", line.MediaId)
		end):SetImage("icon16/monitor_delete.png")

		-- Parameters:
		--   menu    - a DMenu
		--   mediaId - the line's media ID
		--   line    - a DListView_Line (see the function ModLine)
		--   media   - a table with the following keys: title, url, a_sid, a_nick
		hook.Call("WMCPMedialistRowRightClick", nil, menu, line.MediaId, line, t[line.MediaId])

		menu:Open()
	end

	local function ModLine(id, media)
		local line
		for _,iline in pairs(medialist.Lines) do
			if iline.MediaId == id then
				line = iline
				break
			end
		end

		if not line then
			line = medialist:AddLine(id)
			line:SetCursor("hand")
			line.ActiveCond = function(pself)
				local clip = wmcp.GetClip()
				return clip and clip:getUrl() == pself.Url
			end
		end

		line.MediaId = id

		if media.title then
			line:SetColumnText(2, media.title):SetFont("WMCPUINormalFont")
		end
		if media.a_sid and media.a_nick then
			local plycell = line:Add("WMCPlayerCell")
			plycell.NickLabel:SetFont("WMCPUINormalFont")
			plycell:SetSIDNick(media.a_sid, media.a_nick)
			line:SetColumnText(3, plycell)
		end
		if media.url then
			line.Url = media.url
		end
	end

	for id,media in pairs(t) do
		ModLine(id, media)
	end

	nettable.setChangeListener(t, "UIUpdater", function(e)
		if not IsValid(medialist) then return end

		for id, media in pairs(e.modified) do
			ModLine(id, media)
		end

		-- Loops through checking if a media table was deleted.
		-- If so, then remove the line from the medialist.
		for id,v in pairs(e.deleted) do
			-- Skip if it's not a bool and the value isn't "true".
			if v ~= true then continue end

			for _,line in pairs(medialist.Lines) do
				if line.MediaId == id then
					local lineid = line:GetID()
					if lineid then medialist:RemoveLine(lineid) end
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
