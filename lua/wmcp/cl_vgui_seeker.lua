local PANEL = {}

function PANEL:Init()
	self:SetCursor("hand")
end

local DEFAULT_SEEKERBG = Color(108, 122, 137, 200)

function PANEL:Paint(w, h)
	local duration = self.Duration

	local frac = 0
	if self.Elapsed and duration then frac = self.Elapsed/duration end

	surface.SetDrawColor(self.SeekerBG or DEFAULT_SEEKERBG)

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

function PANEL:OnCursorMoved(x, y)
	if input.IsMouseDown(MOUSE_LEFT) then
		local frac = x / self:GetWide()
		self:OnSeeking(frac)
	end
end
function PANEL:OnMouseReleased(mcode)
	if mcode == MOUSE_LEFT then
		local x = self:ScreenToLocal(gui.MouseX())
		self:OnSeeked(x / self:GetWide())
	end
end

function PANEL:OnSeeking(frac) end
function PANEL:OnSeeked(frac) end

derma.DefineControl("WMCMediaSeeker", "", PANEL, "DPanel")