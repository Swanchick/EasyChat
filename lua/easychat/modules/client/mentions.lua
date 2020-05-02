local EC_MENTION = CreateConVar("easychat_mentions", "1", FCVAR_ARCHIVE, "Highlights messages containing your name")
local EC_MENTION_FLASH = CreateConVar("easychat_mentions_flash_window", "1", "Flashes your window when you get mentioned")
local EC_MENTION_COLOR = CreateConVar("easychat_mentions_color", "244 167 66", "Color of the mentions")
local EC_TIMESTAMPS_12 = GetConVar("easychat_timestamps_12")

EasyChat.RegisterConvar(EC_MENTION, "Color messages containing your name")
EasyChat.RegisterConvar(EC_MENTION_FLASH, "Flashes your game when you are mentioned")

local function undecorate_nick(nick)
	if ec_markup then
		return ec_markup.Parse(nick, nil, true):GetText():lower()
	else
		return nick:gsub("<.->", ""):lower()
	end
end

local mentions_frame = nil
local function create_mention_panel()
	local frame = vgui.Create("DFrame")
	frame.btnMaxim:Hide()
	frame.btnMinim:Hide()
	frame.btnClose:SetSize(30, 30)
	frame.btnClose:SetZPos(10)
	frame.btnClose:SetFont("DermaDefaultBold")
	frame.btnClose:SetText("X")

	frame:SetTitle("Missed Mentions")
	frame.lblTitle:SetFont("EasyChatFont")

	local btn_ok = frame:Add("DButton")
	btn_ok:SetText("Ok")
	btn_ok:SetTall(30)
	btn_ok:Dock(BOTTOM)
	btn_ok:DockMargin(5, 5, 5, 5)
	btn_ok.DoClick = function() frame:Close() end

	local richtext = frame:Add("RichText")
	richtext:Dock(FILL)
	richtext:DockMargin(5, 5, 5, 5)
	frame.RichText = richtext

	if not EasyChat.UseDermaSkin then
		frame.lblTitle:SetTextColor(EasyChat.TextColor)
		frame.btnClose:SetTextColor(EasyChat.TextColor)
		frame.btnClose.Paint = function() end

		EasyChat.BlurPanel(frame, 0, 0, 0, 0)

		frame.Paint = function(self, w, h)
			surface.SetDrawColor(EasyChat.OutlayColor)
			surface.DrawRect(0, 0, w, 25)

			local r, g, b, a = EasyChat.TabColor:Unpack()
			surface.SetDrawColor(r, g, b, a)
			surface.DrawRect(0, 25, w, h - 25)

			surface.SetDrawColor(EasyChat.OutlayOutlineColor)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		btn_ok:SetTextColor(EasyChat.TextColor)
		btn_ok.Paint = function(self,w,h)
			local col1, col2 = EasyChat.OutlayColor, EasyChat.TabOutlineColor
			if self:IsHovered() then
				col1 = Color(col1.r + 50, col1.g + 50, col1.b + 50, col1.a + 50)
				col2 = Color(255 - col2.r, 255 - col2.g, 255 - col2.b, 255 - col2.a)
			end

			surface.SetDrawColor(col1)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
	end

	frame:SetSize(400, 400)
	frame:SetVisible(false)

	mentions_frame = frame
end

local function show_missed_mentions()
	if not IsValid(mentions_frame) then return end

	mentions_frame:SetVisible(true)
	mentions_frame:Center()
	mentions_frame:MakePopup()
end

local old_focus = true
hook.Add("Think", "EasyChatModuleMention", function()
	local has_focus = system.HasFocus()
	if old_focus ~= has_focus and has_focus then
		show_missed_mentions()
	end

	old_focus = has_focus
end)

hook.Add("AFK", "EasyChatModuleMention", function(ply, is_afk)
	if ply == LocalPlayer() and not is_afk then
		show_missed_mentions()
	end
end)

hook.Add("OnPlayerChat", "EasyChatModuleMention", function(ply, msg, is_team, is_dead, is_local)
	if not EC_MENTION:GetBool() then return end

	-- could be run too early
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	if ply == lp then return end

	local original_msg = msg

	msg = msg:lower()
	local undec_nick = undecorate_nick(lp:Nick()):PatternSafe()
	if not msg:match("^[%!%.%/]") and msg:match(undec_nick) then
		if EC_MENTION_FLASH:GetBool() then
			system.FlashWindow()
		end

		EasyChat.FlashTab("Global")

		local msg_components = {}
		if is_dead then
			EasyChat.AddDeadTag(msg_components)
		end

		if is_team then
			EasyChat.AddTeamTag(msg_components)
		end

		if is_local then
			EasyChat.AddLocalTag(msg_components)
		end

		if IsValid(ply) then
			EasyChat.AddNameTags(ply, msg_components)
		end

		table.insert(msg_components, ply)
		table.insert(msg_components, color_white)
		table.insert(msg_components, ": ")

		local r, g, b = EC_MENTION_COLOR:GetString():match("^(%d%d?%d?) (%d%d?%d?) (%d%d?%d?)")
		r = r and tonumber(r) or 244
		g = g and tonumber(g) or 167
		b = b and tonumber(b) or 66

		table.insert(msg_components, Color(r, g, b))
		table.insert(msg_components, original_msg)
		chat.AddText(unpack(msg_components))

		if not system.HasFocus() or (lp.IsAFK and lp:IsAFK()) then
			if not IsValid(mentions_frame) then
				create_mention_panel()
			end

			EasyChat.AddText(mentions_frame.RichText, unpack(msg_components))
		end

		return true -- hide chat message
	end
end)

return "Mentions"
