------------------------------------------
------------------------------------------
function ulx.gplay(calling_ply, url, title, force)
	-- If you really really really want a blank title just use " " for title.
	if title == "" then
		title = nil
	end

	-- Callback is called after the URL was verified and before
	-- the media is broadcast to the clients.
	local function queryCallback(queryError, queryData)
		-- ULX handles an invalid player as the server console so we don't
		-- need to add anything to fix calling_ply.
		if queryError then
			ULib.tsayError(calling_ply, ("Invalid url provided: " .. queryError), true)
		else
			local title = title or queryData.title
			ulx.fancyLogAdmin(calling_ply, "#A played #s", title)
		end
	end

	local err = wmcp.GlobalPlay(url, title, force, queryCallback)

	if err then
		ULib.tsayError(calling_ply, err, true)
	end
end

local gplay = ulx.command("WMCP", "ulx gplay", ulx.gplay, "!gplay")
gplay:addParam{ type = ULib.cmds.StringArg, hint = "url",  ULib.cmds.optional }
gplay:addParam{ type = ULib.cmds.StringArg, hint= "title", ULib.cmds.optional }
gplay:addParam{ type = ULib.cmds.BoolArg, hint = "force",  ULib.cmds.optional }
gplay:defaultAccess( ULib.ACCESS_ADMIN )
gplay:help("Plays a media URL on clients through WMCP.")

------------------------------------------
------------------------------------------
function ulx.gstop(calling_ply, force)
	wmcp.GlobalStop(force)
	ulx.fancyLogAdmin(calling_ply, "#A stopped media")
end

local gstop = ulx.command("WMCP", "ulx gstop", ulx.gstop, "!gstop")
gstop:addParam{ type = ULib.cmds.BoolArg, hint = "force", ULib.cmds.optional }
gstop:defaultAccess( ULib.ACCESS_ADMIN )
gstop:help("Ends music being played by WMCP.")
