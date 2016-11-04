wmcp = {}

function wmcp.include_cl(file)
	if SERVER then AddCSLuaFile(file) end
	if CLIENT then return include(file) end
end
function wmcp.include_sv(file)
	if SERVER then return include(file) end
end
function wmcp.include_sh(file)
	return wmcp.include_cl(file) or wmcp.include_sv(file)
end

-- Load libraries
wmcp.medialib = wmcp.include_sh("wmcp_libs/medialib.lua")
if not nettable then wmcp.include_sh("wmcp_libs/nettable.lua") end

-- Load WMCP
wmcp.include_sv("wmcp/sh_permissions.lua")

wmcp.include_sv("wmcp/sv_media.lua")
wmcp.include_sv("wmcp/sv_medialist.lua")

wmcp.include_cl("wmcp/cl_skin.lua")

wmcp.include_cl("wmcp/cl_vgui_plycell.lua")
wmcp.include_cl("wmcp/cl_vgui_seeker.lua")
wmcp.include_cl("wmcp/cl_videoselector.lua")
wmcp.include_cl("wmcp/cl_ui.lua")

wmcp.include_cl("wmcp/cl_key.lua")
wmcp.include_cl("wmcp/cl_hudplayer.lua")

wmcp.include_cl("wmcp/cl_media.lua")

wmcp.include_cl("wmcp/cl_videodebug.lua")
