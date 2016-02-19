local function playFunc(caller, targets, url, title, force, silent)
	-- If you really really really want a blank title just use " " for title.
	if title == "" then
		title = nil
	end

	wmcp.PlayFor(targets, url, title, {force = force}, function(err, data)
		-- ULX handles an invalid player as the server console so we don't
		-- need to add anything to fix caller.

		if err then
			ULib.tsayError(caller, err, true)
		else
			local title = title or data.title
			local blah = "#A played #s" .. (targets and " on #T" or "")

			if silent then
				ulx.fancyLogAdmin(caller, silent, blah, title, targets)
			else
				ulx.fancyLogAdmin(caller, blah, title, targets)
			end
		end
	end)
end

local function stopFunc(caller, targets, force, silent)
	wmcp.StopFor(targets, {force = force})

	local blah = "#A stopped media".. (targets and " on #T" or "")

	if silent then
		ulx.fancyLogAdmin(caller, silent, blah, targets)
	else
		ulx.fancyLogAdmin(caller, blah, targets)
	end
end

------------------------------------------
------------------------------------------
function ulx.gplay(caller, url, title, force, silent)
	playFunc(caller, nil, url, title, force, silent)
end

local gplay = ulx.command("WMCP", "ulx gplay", ulx.gplay, "!gplay")
gplay:addParam{ type = ULib.cmds.StringArg, hint = "url" }
gplay:addParam{ type = ULib.cmds.StringArg, hint= "title", ULib.cmds.optional }
gplay:addParam{ type = ULib.cmds.BoolArg, hint = "force",  ULib.cmds.optional }
gplay:addParam{ type = ULib.cmds.BoolArg, hint = "silent",  ULib.cmds.optional }
gplay:defaultAccess( ULib.ACCESS_ADMIN )
gplay:help("Plays a media URL on clients through WMCP.")

------------------------------------------
------------------------------------------
function ulx.gstop(caller, force, silent)
	stopFunc(caller, nil, force, silent)
end

local gstop = ulx.command("WMCP", "ulx gstop", ulx.gstop, "!gstop")
gstop:addParam{ type = ULib.cmds.BoolArg, hint = "force", ULib.cmds.optional }
gstop:addParam{ type = ULib.cmds.BoolArg, hint = "silent",  ULib.cmds.optional }
gstop:defaultAccess( ULib.ACCESS_ADMIN )
gstop:help("Ends music being played by WMCP.")

------------------------------------------
------------------------------------------
function ulx.pplay(caller, targets, url, title, force, silent)
	playFunc(caller, targets, url, title, force, silent)
end

local pplay = ulx.command("WMCP", "ulx pplay", ulx.pplay, "!pplay")
pplay:addParam{ type = ULib.cmds.PlayersArg }
pplay:addParam{ type = ULib.cmds.StringArg, hint = "url" }
pplay:addParam{ type = ULib.cmds.StringArg, hint= "title", ULib.cmds.optional }
pplay:addParam{ type = ULib.cmds.BoolArg, hint = "force",  ULib.cmds.optional }
pplay:addParam{ type = ULib.cmds.BoolArg, hint = "silent",  ULib.cmds.optional }
pplay:defaultAccess( ULib.ACCESS_ADMIN )
pplay:help("Plays a media URL on clients through WMCP.")

------------------------------------------
------------------------------------------
function ulx.pstop(caller, targets, force, silent)
	stopFunc(caller, targets, force, silent)
end

local pstop = ulx.command("WMCP", "ulx pstop", ulx.pstop, "!pstop")
pstop:addParam{ type = ULib.cmds.PlayersArg }
pstop:addParam{ type = ULib.cmds.BoolArg, hint = "force", ULib.cmds.optional }
pstop:addParam{ type = ULib.cmds.BoolArg, hint = "silent",  ULib.cmds.optional }
pstop:defaultAccess( ULib.ACCESS_ADMIN )
pstop:help("Ends music being played by WMCP.")


if not CLIENT then return end

hook.Add("WMCPMedialistRowRightClick", "ulxhtinges", function(menu, line, url, media)
	menu:AddSpacer()

	local submenu, option = menu:AddSubMenu("Play for", function() end)
	option:SetIcon("icon16/music.png")

	for _,plr in pairs(player.GetAll()) do
		submenu:AddOption(plr:Nick(), function()
			RunConsoleCommand("ulx", "pplay", plr:Nick(), url, line:GetColumnText(2))
		end):SetIcon("icon16/emoticon_tongue.png")
	end
end, HOOK_HIGH) -- high hook thing so it goes aboeve eveyrthing in the worlds
