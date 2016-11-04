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

function wmcp.Persist()
	file.Write("wmcp.txt", util.TableToJSON(t, true))
end

wmcp.AddSecuredConcommand("wmcp_add", "add", function(ply, cmd, args, raw)
	local url = args[1]

	local service = wmcp.medialib.load("media").guessService(url)
	if not service then ply:ChatPrint("Invalid url provided: no service found") return end

	service:query(url, function(err, data)
		if err then ply:ChatPrint("Invalid url provided: " .. err) return end

		table.insert(t, {title = data.title, url = url, a_nick = ply:Nick(), a_sid = ply:SteamID()})
		nettable.commit(t)

		wmcp.Persist()
	end)
end)

concommand.Add("wmcp_settitle", function(ply, cmd, args, raw)
	local id = tonumber(args[1])
	local newTitle = args[2]

	local entry = t[id or -1]
	if entry then
		local addedByPly = ply:SteamID() == entry.a_sid

		ply:WMCP_IfPermissionAsync(addedByPly and "modifyowned" or "modify", function()
			entry.title = newTitle
			nettable.commit(t)
			wmcp.Persist()
		end)
	end
end)
concommand.Add("wmcp_del", function(ply, cmd, args, raw)
	local id = tonumber(args[1])
	local entry = t[id or -1]

	if entry then
		ply:WMCP_IfPermissionAsync(addedByPly and "modifyowned" or "modify", function()
			table.remove(t, id)
			nettable.commit(t)
			wmcp.Persist()
		end)
	end
end)

wmcp.AddSecuredConcommand("wmcp_gplay", "playglobal", function(ply, cmd, args, raw)
	local url = args[1]
	local title = args[2]

	wmcp.PlayFor(nil, url, {
		meta = {
			title = title
		},
		onError = function(err)
			ply:ChatPrint(err)
		end
	})
end)

wmcp.AddSecuredConcommand("wmcp_gstop", "playglobal", function(ply, cmd, args, raw)
	wmcp.StopFor(nil)
end)