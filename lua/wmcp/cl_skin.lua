SKIN = {}

SKIN.GwenTexture	= Material( "gwenskin/GModDefault.png" )

SKIN.Colours = {}

SKIN.Colours.Window = {}
SKIN.Colours.Window.TitleActive			= Color(255, 255, 255)
SKIN.Colours.Window.TitleInactive		= GWEN.TextureColor( 4 + 8 * 1, 508 )
SKIN.Colours.Window.Background			= Color(236, 236, 236)
SKIN.Colours.Window.Outline 			= Color(255, 255, 255)
SKIN.Colours.Window.TitleBackground 	= Color(44, 62, 80)

SKIN.Colours.Button = {}
SKIN.Colours.Button.Normal				= Color(255, 255, 255)
SKIN.Colours.Button.Hover				= Color(255, 255, 255)
SKIN.Colours.Button.Down				= Color(255, 255, 255)
SKIN.Colours.Button.Disabled			= Color(255, 255, 255)

SKIN.Colours.Button.BackgroundNormal				= Color(108, 122, 137)
SKIN.Colours.Button.BackgroundHover					= Color(149, 165, 166)
SKIN.Colours.Button.BackgroundDown					= GWEN.TextureColor( 4 + 8 * 2, 500 )
SKIN.Colours.Button.BackgroundDisabled				= Color(191, 191, 191)
SKIN.Colours.Button.BackgroundOutline				= Color(255, 255, 255)

SKIN.Colours.List = {}
SKIN.Colours.List.Outline				= Color(255, 255, 255)

SKIN.Colours.Tab = {}
SKIN.Colours.Tab.Active = {}
SKIN.Colours.Tab.Active.Normal			= GWEN.TextureColor( 4 + 8 * 4, 508 )
SKIN.Colours.Tab.Active.Hover			= GWEN.TextureColor( 4 + 8 * 5, 508 )
SKIN.Colours.Tab.Active.Down			= GWEN.TextureColor( 4 + 8 * 4, 500 )
SKIN.Colours.Tab.Active.Disabled		= GWEN.TextureColor( 4 + 8 * 5, 500 )

SKIN.Colours.Tab.Inactive = {}
SKIN.Colours.Tab.Inactive.Normal		= GWEN.TextureColor( 4 + 8 * 6, 508 )
SKIN.Colours.Tab.Inactive.Hover			= GWEN.TextureColor( 4 + 8 * 7, 508 )
SKIN.Colours.Tab.Inactive.Down			= GWEN.TextureColor( 4 + 8 * 6, 500 )
SKIN.Colours.Tab.Inactive.Disabled		= GWEN.TextureColor( 4 + 8 * 7, 500 )

SKIN.Colours.Label = {}
SKIN.Colours.Label.Default				= Color(0, 0, 0)
SKIN.Colours.Label.Bright				= Color(0, 0, 0)
SKIN.Colours.Label.Dark					= Color(0, 0, 0)
SKIN.Colours.Label.Highlight			= Color(255, 127, 0)

SKIN.Colours.TooltipText = GWEN.TextureColor( 4 + 8 * 26, 500 )

SKIN.Colors = SKIN.Colours -- Garry you idiot

surface.CreateFont("WMCPUIFrameFont", {
	font = "Roboto",
	size = 16
})
surface.CreateFont("WMCPUINormalFont", {
	font = "Roboto",
	size = 14
})
surface.CreateFont("WMCPUINormalFontBold", {
	font = "Roboto",
	size = 14,
	weight = 800
})
SKIN.fontFrame = "WMCPUIFrameFont"

-- Kids, don't do this at home
function SKIN:UpdateLabel(lbl)
	if lbl:GetFont() == "DermaDefault" then lbl:SetFont("WMCPUINormalFont") end
end
function SKIN:UpdateFrameLabel(lbl)
	lbl:SetFont("WMCPUIFrameFont")
end
 
function SKIN:PaintFrame( panel, w, h )
	local isGrayed = not panel:HasHierarchicalFocus()

	surface.SetDrawColor(self.Colors.Window.Background)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(self.Colors.Window.Outline)
	surface.DrawOutlinedRect(0, 0, w, h)

	surface.SetDrawColor(self.Colors.Window.TitleBackground)
	surface.DrawRect(1, 1, w-2, 23)

	self:UpdateFrameLabel(panel.lblTitle)

	return true
end

function SKIN:PaintButton( panel, w, h )
	if ( !panel.m_bBackground ) then return end
	
	local clr = panel.BGTint or self.Colors.Button.BackgroundNormal
	
	if ( panel.Depressed || panel:IsSelected() || panel:GetToggle() ) then
		clr = self.Colors.Button.BackgroundDown
	end
	
	if ( panel.Hovered ) then
		clr = self.Colors.Button.BackgroundHover
	end

	if ( panel:GetDisabled() ) then
		clr = self.Colors.Button.BackgroundDisabled
	end
	
	surface.SetDrawColor(clr)
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(self.Colors.Button.BackgroundOutline)
	surface.DrawOutlinedRect(0, 0, w, h)

	self:UpdateLabel(panel)
end

function SKIN:PaintListView( panel, w, h )
	surface.SetDrawColor(self.Colors.List.Outline)
	surface.DrawOutlinedRect(0, 0, w, h)
end
 
derma.DefineSkin("WMCPUI", "Fun fun fun fun", SKIN)