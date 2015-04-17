wmcp = {}

function wmcp.include_cl(file)
	if SERVER then AddCSLuaFile(file) end
	if CLIENT then include(file) end
end
function wmcp.include_sv(file)
	if SERVER then include(file) end
end
function wmcp.include_sh(file)
	wmcp.include_cl(file)
	wmcp.include_sv(file)
end

-- Load libraries
if not medialib then wmcp.include_sh("wmcp_libs/medialib.lua") end
if not nettable then wmcp.include_sh("wmcp_libs/nettable.lua") end

-- Load WMCP
wmcp.include_sv("wmcp/sv_medialist.lua")

wmcp.include_cl("wmcp/cl_skin.lua")

wmcp.include_cl("wmcp/cl_vgui_plycell.lua")
wmcp.include_cl("wmcp/cl_vgui_seeker.lua")
wmcp.include_cl("wmcp/cl_ui.lua")

wmcp.include_cl("wmcp/cl_key.lua")
wmcp.include_cl("wmcp/cl_hudplayer.lua")

wmcp.include_cl("wmcp/cl_media.lua")