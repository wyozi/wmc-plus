local PANEL = {}

function PANEL:Init()
	self.AvatarButton = self:Add("DButton")
	self.Avatar = self:Add("AvatarImage")

	self.NickLabel = self:Add("DLabel")
	self.NickLabel:SetMouseInputEnabled(false)

	self.Avatar:SetMouseInputEnabled(false)
	self.AvatarButton.DoClick = function()
		if self.Sid64 then gui.OpenURL("http://steamcommunity.com/profiles/" .. self.Sid64) end
	end

	self:SetMouseInputEnabled(false)
end
function PANEL:SetPlayer(ply)
	self.Avatar:SetPlayer(ply, 64)
	self.NickLabel:SetText(ply:Nick())

	self.Sid64 = ply:SteamID64()
end
function PANEL:SetSIDNick(sid, nick)
	sid = util.SteamIDTo64(sid)

	self.Avatar:SetSteamID(sid, 64)
	self.NickLabel:SetText(nick)

	self.Sid64 = sid
end
function PANEL:PerformLayout()
	local avatarsize = self:GetTall() - 2
	self.Avatar:SetPos(1, 1)
	self.Avatar:SetSize(avatarsize, avatarsize)
	self.AvatarButton:SetPos(1, 1)
	self.AvatarButton:SetSize(avatarsize, avatarsize)

	local nicktall = self.NickLabel:GetTall()
	self.NickLabel:SetPos(1 + avatarsize + 3, 0)
	self.NickLabel:SetSize(self:GetWide() - 1 - avatarsize, self:GetTall())
end

function PANEL:ApplySchemeSettings()
end

local function Delegate(name)
	PANEL[name] = function(self, ...)
		local par = self:GetParent()
		if IsValid(par) and par[name] then par[name](par, ...) end
	end
end

Delegate "OnMousePressed"

function PANEL:OnCursorEntered()
	local par = self:GetParent()
	if IsValid(par) then par.Hovered = true end
end
function PANEL:OnCursorExited()
	local par = self:GetParent()
	if IsValid(par) then par.Hovered = false end
end

derma.DefineControl("WMCPlayerCell", "", PANEL, "Panel")