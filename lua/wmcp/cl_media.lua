function wmcp.Play(url, overridingMeta)
	if IsValid(wmcp.Clip) then wmcp.Clip:stop() end

	local service = medialib.load("media").guessService(url)
	local clip = service:load(url)
	clip:play()
	clip:setVolume(wmcp.GetVolume())

	wmcp.Clip = clip
	wmcp.ClipMeta = nil
	wmcp.ClipOverridingMeta = overridingMeta

	service:query(url, function(err, data)
		if data and (not IsValid(wmcp.Clip) or wmcp.Clip:getUrl() == url) then
			wmcp.ClipMeta = data
		end
	end)

	return clip
end

net.Receive("wmcp_gplay", function()
	local url, title = net.ReadString(), net.ReadString()
	if title == "" then title = nil end
	wmcp.Play(url, {title = title})
end)

function wmcp.TogglePlay(url)
	local clip = wmcp.Clip
	if not IsValid(clip) then return end

	if clip:isPlaying() then
		clip:pause()
	else
		clip:play()
	end
end

function wmcp.GetClip()
	return wmcp.Clip
end

function wmcp.GetClipMeta()
	local meta = wmcp.ClipMeta
	local overriding = wmcp.ClipOverridingMeta

	local m = meta and table.Copy(meta) or {}

	if overriding then
		table.Merge(m, overriding)
	end

	return m
end

local wmcp_volume = CreateConVar("wmcp_volume", "1", FCVAR_ARCHIVE)

function wmcp.GetVolume()
	return wmcp_volume:GetFloat()
end

function wmcp.SetVolume(vol)
	wmcp_volume:SetFloat(vol)

	local clip = wmcp.Clip

	if IsValid(clip) then
		clip:setVolume(vol)
	end
end

function wmcp.StopClip()
	local clip = wmcp.Clip

	if IsValid(clip) then
		-- Hacky way to stop anything from happening on clip end.
		-- For example, if a song is started from the GUI, on clip end
		-- the next song on the GUI list will play.
		if clip._events then
			clip._events["ended"] = nil
		end
		clip:stop()
	end

	wmcp.Clip = nil
	wmcp.ClipMeta = nil
	wmcp.ClipOverridingMeta = nil

	if wmcp.IsOpen() then
		local player = wmcp.Frame.Player
		player.Title:SetText("")
		player.Seeker:SetElapsed(nil)
		player.Seeker:SetDuration(nil)
	end
end

concommand.Add("wmcp_stop", function()
	wmcp.StopClip()
end)

-- if not 0 then music is muted when GMOD's window isn't focused.
local wmcp_muteifunfocused = CreateConVar("wmcp_muteifunfocused", "0", FCVAR_ARCHIVE)
local snd_mute_losefocus = GetConVar("snd_mute_losefocus")

-- Non-Windows operating systems don't have a correct system.HasFocus() :|
if system.IsWindows() then
	function wmcp.UnfocusedMuteThinkHook()
		local clip = wmcp.Clip

		if not IsValid(clip) then
			return
		end

		if system.HasFocus() then
			local wmcpVolume = wmcp.GetVolume()

			if clip:getVolume() ~= wmcpVolume then
				clip:setVolume(wmcpVolume)
			end
		elseif snd_mute_losefocus:GetBool() or wmcp_muteifunfocused:GetBool() then
			if clip:getVolume() ~= 0 then
				clip:setVolume(0)
			end
		end
	end

	hook.Add("Think", "WMCPUnfocusedMute", wmcp.UnfocusedMuteThinkHook)
end
