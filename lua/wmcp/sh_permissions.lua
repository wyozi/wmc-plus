local checkPerm

if CAMI then
	CAMI.RegisterPrivilege {
		Name = "wmcp_playglobal",
		Description = "Play songs for every player.",
		MinAccess = "admin"
	}
	CAMI.RegisterPrivilege {
		Name = "wmcp_add",
		Description = "Add new songs to the global playlist",
		MinAccess = "admin"
	}
	CAMI.RegisterPrivilege {
		Name = "wmcp_modify",
		Description = "Modify/delete any song.",
		MinAccess = "admin"
	}
	CAMI.RegisterPrivilege {
		Name = "wmcp_modifyowned",
		Description = "Modify/delete songs added by the user.",
		MinAccess = "user"
	}

	checkPerm = function(p, perm, callback)
		CAMI.PlayerHasAccess(p, "wmcp_" .. perm, callback)
	end
else
	checkPerm = function(p, perm, callback)
		callback(p:IsAdmin())
	end
end

local availablePermissions = {
	["playglobal"] = true, ["add"] = true, ["modify"] = true, ["modifyowned"] = true
}

local Player = FindMetaTable("Player")

-- Calls callback with boolean parameter indicating whether player is allowed
-- to do action perm
function Player:WMCP_CheckPermissionAsync(perm, callback)
	if not availablePermissions[perm] then error("querying for invalid permission: " .. perm) end

	checkPerm(self, perm, callback)
end

-- Calls callback with no parameters only if user is allowed to do action perm
-- Otherwise prints a message
function Player:WMCP_IfPermissionAsync(perm, callback)
	self:WMCP_CheckPermissionAsync(perm, function(allowed)
		if allowed then
			callback()
		else
			self:ChatPrint("Access to '" .. perm .. "' denied.")
		end
	end)
end