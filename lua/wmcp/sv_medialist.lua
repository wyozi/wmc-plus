util.AddNetworkString("wmcp_play_msg")
util.AddNetworkString("wmcp_stop_msg")

local t = nettable.get("WMCPMedia.Main")

if file.Exists("wmcp.txt", "DATA") then
	local json = file.Read("wmcp.txt", "DATA")
	local stuff = util.JSONToTable(json)

	-- We're using an older WMCP data file that didn't use URLs as the table key
	if stuff[1] then
		file.Write("backup.wmcp.txt", json)
		-- do this time thing for date sorting and stuff
		local time = os.time() - #stuff
		local new = {}

		for i, media in ipairs(stuff) do
			new[media.url] = media
			media.url = nil
			media.date = time
			time = time + 1
		end

		table.Merge(t, new)
		wmcp.Persist()
	else
		table.Merge(t, stuff)
	end

	nettable.commit(t)
else
	-- Add 'i' to 'time' so the items are sorted by date in descending order.
	local i = 0
	local time = os.time()

	local function Add(text, url)
		i = i + 1

		t[url] = {
			title  = text,
			date   = (time + i),
			a_nick = "Hobbes",
			a_sid  = "STEAM_0:1:68224691",
		}
	end

	Add("Welcome to WMC Plus!", "https://www.youtube.com/watch?v=rlGF5ma3gdA")
	Add("Double click a line to play the song on that line", "https://www.youtube.com/watch?v=pGH2zNU29FU")
	Add("Right click a line to access its options", "https://www.youtube.com/watch?v=ljTYQ5ZZj7E")
	Add("You can remove these songs by right clicking and selecting 'Delete'", "https://www.youtube.com/watch?v=X7yiV6226Xg")

	nettable.commit(t)
end

function wmcp.Persist()
	file.Write("wmcp.txt", util.TableToJSON(t, true))
end

local wmcp_allowed = CreateConVar("wmcp_allowedgroup", "admin", FCVAR_ARCHIVE,
	"The minimum usergroup that is allowed to add/remove/play videos.")

function wmcp.IsAllowed(plr, act)
	if not IsValid(plr) then return true end -- server console
	if plr:IsSuperAdmin() then return true end -- always allowed

	local g = wmcp_allowed:GetString()
	-- Check for default usergroups
	if g == "admin" or g == "admins" then return plr:IsAdmin() end

	-- Check for ULX usergroups
	if plr.CheckGroup and plr:CheckGroup(g) then return true end

	-- Check for GMod usergroups
	if plr:IsUserGroup(g) then return true end

	return false
end

-- plrs can be a table of players, a player, or nil (to send to everyone)
function wmcp.PlayFor(plrs, url, title, opts, callback)
	local service = medialib.load("media").guessService(url)

	if not service then
		callback("Invalid url provided: no service found", nil)
		return
	end

	service:query(url, function(err, data)
		if callback then
			-- check if callback wants to cancel
			if callback(err, data) == true then
				return
			end
		end

		if err then return end

		net.Start("wmcp_play_msg")
		net.WriteString(url)
		net.WriteString(title or data.title)
		net.WriteTable(opts or {})
		if plrs then
			net.Send(plrs)
		else
			net.Broadcast()
		end
	end)
end

-- plrs can be a table of players, a player, or nil (to send to everyone)
function wmcp.StopFor(plrs, opts)
	net.Start("wmcp_stop_msg")
	net.WriteTable(opts or {})
	if plrs then
		net.Send(plrs)
	else
		net.Broadcast()
	end
end

hook.Add("PlayerSay", "WMCPStop", function(plr, text)
	if IsValid(plr) and text:StartWith("!stop") then
		wmcp.StopFor(plr, {force = true})
	end
end)

local function printWrapper(plr, msg)
	if IsValid(plr) then
		plr:ChatPrint(msg)
	else
		print(msg)
	end
end

concommand.Add("wmcp_add", function(plr, cmd, args, raw)
	if not wmcp.IsAllowed(plr, cmd) then
		printWrapper(plr, "access denied")
		return
	end

	local url = args[1]

	if not url then
		printWrapper(plr, "invalid data given")
		return
	end

	local service = medialib.load("media").guessService(url)

	if not service then
		printWrapper(plr, "Invalid url provided: no service found")
		return
	end

	service:query(url, function(err, data)
		if err then
			printWrapper(plr, "Invalid url provided: " .. err)
			return
		end

		t[url] = {
			title  = data.title,
			date   = os.time(),
			a_nick = plr:Nick(),
			a_sid  = plr:SteamID()
		}

		nettable.commit(t)
		wmcp.Persist()
	end)
end)

concommand.Add("wmcp_settitle", function(plr, cmd, args, raw)
	if not wmcp.IsAllowed(plr, cmd) then
		printWrapper(plr, "access denied")
		return
	end

	local url = args[1]
	local newTitle = args[2]

	if not url or not newTitle then
		printWrapper(plr, "invalid data given")
		return
	end

	local media = t[url]

	if not media then
		printWrapper(plr, "media does not exist")
		return
	end

	media.title = newTitle

	nettable.commit(t)
	wmcp.Persist()
end)

concommand.Add("wmcp_gplay", function(plr, cmd, args, raw)
	if not wmcp.IsAllowed(ply, cmd) then
		printWrapper(plr, "access denied")
		return
	end

	local url = args[1]
	local title = args[2]
	local force = tobool(args[3])

	-- Unnecessary thingy I'm keeping to keep wmcp_play work the
	-- same as the 'ulx gplay' command.
	if title == "" then
		title = nil
	end

	wmcp.PlayFor(nil, url, title, {force = force}, function(err, data)
		if err then
			printWrapper(plr, err)
		end
	end)
end)

concommand.Add("wmcp_gstop", function(plr, cmd, args, raw)
	if not wmcp.IsAllowed(ply, cmd) then
		printWrapper(plr, "access denied")
		return
	end

	local force = tobool(args[1])

	wmcp.StopFor(nil, {force = force})
end)

concommand.Add("wmcp_del", function(plr, cmd, args, raw)
	if not wmcp.IsAllowed(ply, cmd) then
		printWrapper(plr, "access denied")
		return
	end

	local url = args[1]

	if not url then
		printWrapper(plr, "invalid url given")
		return
	end

	if not t[url] then
		printWrapper(plr, "media does not exist")
		return
	end

	t[url] = nil

	nettable.commit(t)
	wmcp.Persist()
end)
