local checkPerm

if CAMI then
	CAMI.RegisterPrivilege {
		Name = "wmcp_playglobal",
		MinAccess = "admin"
	}
	CAMI.RegisterPrivilege {
		Name = "wmcp_add",
		MinAccess = "admin"
	}
	CAMI.RegisterPrivilege {
		Name = "wmcp_modify",
		MinAccess = "admin"
	}

	checkPerm = function(p, perm, callback)
		CAMI.PlayerHasAccess(p, "wmcp_" .. perm, callback)
	end

	print("CAMI :))")
else
	checkPerm = function(p, perm, callback)
		callback(p:IsAdmin())
	end
end

local availablePermissions = {
	["playglobal"] = true, ["add"] = true, ["modify"] = true
}

local Player = FindMetaTable("Player")
function Player:WMCP_CheckPermissionAsync(perm, callback)
	if not availablePermissions[perm] then error("querying for invalid permission: " .. perm) end

	checkPerm(self, perm, callback)
end