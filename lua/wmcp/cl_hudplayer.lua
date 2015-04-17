hook.Add("WMCPPostOpenUI", "HudPlayer", function(frame)
	-- Give player time to position
	timer.Simple(0.1, function()
		if IsValid(wmcp.MiniPlayer) then
			wmcp.MiniPlayer:MakePopup() -- HACK!

			local sx, sy = frame.Player:LocalToScreen(0, 0)
			wmcp.MiniPlayer:SizeTo(frame.Player:GetWide(), -1, 0.5)
			wmcp.MiniPlayer:MoveTo(sx, sy, 0.5, nil, nil, function(_, pnl) pnl:Remove() end)
		end
	end)
end)

local function CreateMiniPlayer()
	local miniPlayer = vgui.Create("EditablePanel")
	miniPlayer:SetKeyBoardInputEnabled(false)
	miniPlayer:SetMouseInputEnabled(false)
	function miniPlayer:Paint(w, h)
		local clip = wmcp.GetClip()
		if not IsValid(clip) or not clip:isPlaying() then
			return
		end

		local meta = wmcp.GetClipMeta()
		
		local frac = 0
		if meta and meta.duration then frac = clip:getTime() / meta.duration end

		surface.SetDrawColor(108, 122, 137, 200)
		surface.DrawRect(0, 0, w*frac, h)

		surface.SetDrawColor(255, 255, 255, 100)
		surface.DrawOutlinedRect(0, 0, w, h)

		if meta and meta.title then
			draw.SimpleText(meta.title, "WMCPUINormalFontBold", w/2, 4, Color(255, 255, 255, 150), TEXT_ALIGN_CENTER)
		end
	end
	return miniPlayer
end

hook.Add("HUDPaint", "WMCPInitialHudPlayer", function()
	if not IsValid(wmcp.MiniPlayer) then
		local miniPlayer = CreateMiniPlayer()
		miniPlayer:SetPos(ScrW()/2 - 175, 0)
		miniPlayer:SetSize(350, 25)

		wmcp.MiniPlayer = miniPlayer
	end

	hook.Remove("HUDPaint", "WMCPInitialHudPlayer")
end)

hook.Add("WMCPPreCloseUI", "HudPlayer", function(frame)
	local player = frame.Player

	local miniPlayer = CreateMiniPlayer()
	miniPlayer:SetSize(player:GetSize())
	local sx, sy = player:LocalToScreen(0, 0)
	miniPlayer:SetPos(sx, sy)

	miniPlayer:SizeTo(350, 25, 0.5)
	miniPlayer:MoveTo(ScrW()/2 - 175, 0, 0.5)

	wmcp.MiniPlayer = miniPlayer
end)