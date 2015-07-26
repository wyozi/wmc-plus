local wmcp_debugvideo = CreateConVar("wmcp_debugvideo", "0", FCVAR_ARCHIVE)

local size_w = 512
local size_h = size_w * (9/16)

hook.Add("HUDPaint", "WMCPVideoDebug", function()
	if not wmcp_debugvideo:GetBool() then return end
	if not IsValid(wmcp.Clip) then return end

	wmcp.Clip:draw(0, 0, size_w, size_h)
end)
