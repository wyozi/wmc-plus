local toggle_down = false
function wmcp.KeysThink()
	if input.IsKeyDown(KEY_F8) then
		if toggle_down then return end

		toggle_down = true
		if wmcp.IsOpen() then
			wmcp.CloseUI()
		else
			wmcp.OpenUI()
		end
	else
		toggle_down = false
	end
end

hook.Add("Think", "WMCPKeyThink", wmcp.KeysThink)