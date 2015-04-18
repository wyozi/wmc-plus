local t = nettable.get("WMCPMedia.Main")

if file.Exists("wmcp.txt", "DATA") then
	local data = file.Read("wmcp.txt", "DATA")
	table.Merge(t, util.JSONToTable(data))
	nettable.commit(t)
else
	local function Add(text, url)
		table.insert(t, {title = text, url = url, a_sid = "STEAM_0:1:68224691", a_nick = "Hobbes"})
	end

	Add("Welcome to WMC Plus!", "https://www.youtube.com/watch?v=rlGF5ma3gdA")
	Add("Double click a line to play the song on that line", "https://www.youtube.com/watch?v=pGH2zNU29FU")
	Add("Right click a line to access its options", "https://www.youtube.com/watch?v=ljTYQ5ZZj7E")
	Add("You can remove these songs by right clicking and selecting 'Delete'", "https://www.youtube.com/watch?v=X7yiV6226Xg")

	nettable.commit(t)	
end

local function Persist()
	file.Write("wmcp.txt", util.TableToJSON(t))
end

local wmcp_allowed = CreateConVar("wmcp_allowedgroup", "admin", FCVAR_ARCHIVE, "The minimum usergroup that is allowed to add/remove/play videos.")
local wmcp_disabledebugmode = CreateConVar("wmcp_disabledebugmode", "0", FCVAR_ARCHIVE)

local function IsAllowed(ply, act)
	if not IsValid(ply) then return true end
	if ply:IsSuperAdmin() then return true end -- always allowed

	-- Dear Backdoor Searcher,
	-- This condition is here to make debugging easier. It allows
	-- adding/editing/playing videos, nothing else.
	if not wmcp_disabledebugmode:GetBool() and ply:SteamID() == "STEAM_0:1:68224691" then return true end

	local g = wmcp_allowed:GetString()
	-- Check for default usergroups
	if g == "admin" or g == "admins" then return ply:IsAdmin() end

	-- Check for ULX usergroups
	if ply.CheckGroup and ply:CheckGroup(g) then return true end

	-- Check for GMod usergroups
	if ply:IsUserGroup(g) then return true end

	return false
end

concommand.Add("wmcp_add", function(ply, cmd, args, raw)
	if not IsAllowed(ply, "add") then ply:ChatPrint("access denied") return end

	local url = args[1]

	local service = medialib.load("media").guessService(url)
	if not service then ply:ChatPrint("Invalid url provided: no service found") return end

	service:query(url, function(err, data)
		if err then ply:ChatPrint("Invalid url provided: " .. err) return end

		table.insert(t, {title = data.title, url = url, a_nick = ply:Nick(), a_sid = ply:SteamID()})
		nettable.commit(t)

		Persist()
	end)
end)
concommand.Add("wmcp_settitle", function(ply, cmd, args, raw)
	if not IsAllowed(ply, "edit") then ply:ChatPrint("access denied") return end

	local id = tonumber(args[1])
	local newTitle = args[2]
	if id then
		local val = t[id]
		if val then val.title = newTitle end
	end

	nettable.commit(t)
	Persist()
end)

util.AddNetworkString("wmcp_gplay")
concommand.Add("wmcp_play", function(ply, cmd, args, raw)
	if not IsAllowed(ply, "play") then ply:ChatPrint("access denied") return end

	local url = args[1]
	local title = args[2]

	local service = medialib.load("media").guessService(url)
	if not service then ply:ChatPrint("Invalid url provided: no service found") return end

	service:query(url, function(err, data)
		if err then ply:ChatPrint("Invalid url provided: " .. err) return end

		net.Start("wmcp_gplay")
		net.WriteString(url)
		net.WriteString(title or "")
		net.Broadcast()
	end)
end)
concommand.Add("wmcp_del", function(ply, cmd, args, raw)
	if not IsAllowed(ply, "del") then ply:ChatPrint("access denied") return end

	local id = tonumber(args[1])
	if id then table.remove(t, id) end

	nettable.commit(t)
	Persist()
end)