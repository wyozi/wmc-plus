local PANEL = {}

function PANEL:Init()
	self:SetCursor("hand")
end
function PANEL:Paint(w, h)
	local elapsed = self.Elapsed
	local duration = self.Duration

	local frac = 0
	if elapsed and duration then frac = elapsed/duration end

	surface.SetDrawColor(108, 122, 137, 200)
	surface.DrawRect(0, 0, w * frac, h)

	surface.SetDrawColor(210, 215, 211)
	surface.DrawOutlinedRect(0, 0, w, h)
end

function PANEL:SetElapsed(time)
	self.Elapsed = time
end
function PANEL:SetDuration(time)
	self.Duration = time
end

function PANEL:OnMouseReleased(mcode)
	if mcode == MOUSE_LEFT then
		local x = self:ScreenToLocal(gui.MouseX())
		self:OnSeeked(x / self:GetWide())
	end
end

function PANEL:OnSeeked(frac) end

derma.DefineControl("WMCMediaSeeker", "", PANEL, "Panel")