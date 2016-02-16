function wmcp.Play(url, overridingMeta)
	if IsValid(wmcp.Clip) then
		wmcp.Clip:stop()
	end

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

	print("[WMCP] Playing media (" .. os.date("%c", os.time()) .. ")")
	print("[WMCP] URL = " .. url)

	return clip
end

local wmcp_enabled = CreateConVar("wmcp_enabled", "1", FCVAR_ARCHIVE)

net.Receive("wmcp_play_msg", function()
	local url = net.ReadString()
	local title = net.ReadString()
	local opts = net.ReadTable()

	if not wmcp_enabled:GetBool() then return end

	if opts.force or hook.Run("WMCPPlayNetMsg", url, title, opts) then
		wmcp.Play(url, {title = title})
	end
end)

net.Receive("wmcp_stop_msg", function()
	local opts = net.ReadTable()

	if not wmcp_enabled:GetBool() then return end

	if opts.force or hook.Run("WMCPStopNetMsg", opts) then
		wmcp.StopClip()
	end
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

	meta = meta and table.Copy(meta) or {}

	if overriding then
		table.Merge(meta, overriding)
	end

	return meta
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

local snd_mute_losefocus = GetConVar("snd_mute_losefocus")
local wmcp_unfocusedmute = CreateConVar("wmcp_unfocusedmute", "2", FCVAR_ARCHIVE,
	"0=Don't mute, 1=Mute, 2=Mute if snd_mute_losefocus")

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
		else
			local muteStyle = math.Clamp(wmcp_unfocusedmute:GetInt(), 0, 2)
			local shouldMute = false

			-- don't need to handle case of muteStyle being 0

			if muteStyle == 1 then -- mute
				shouldMute = true
			elseif muteStyle == 2 then -- mute if snd_mute_losefocus
				shouldMute = snd_mute_losefocus:GetBool()
			end

			if shouldMute and clip:getVolume() ~= 0 then
				clip:setVolume(0)
			end
		end
	end

	hook.Add("Think", "WMCPUnfocusedMute", wmcp.UnfocusedMuteThinkHook)
end
