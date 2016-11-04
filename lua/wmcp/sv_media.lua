util.AddNetworkString("wmcp_gplay")
util.AddNetworkString("wmcp_gstop")

function wmcp.PlayFor(target, url, opts)
	local service = wmcp.medialib.load("media").guessService(url)
	if not service then
		if opts.onError then opts.onError("service not found") end
		return
	end

	service:query(url, function(err, data)
		if err then
			if opts.onError then opts.onError("invalid url provided: " .. err) end
			return
		end

		-- first see if opts contains overriding meta
		local title = opts and opts.meta and opts.meta.title

		-- then fallback to remote meta, and then empty string
		title = title or data.title or ""

		net.Start("wmcp_gplay")
		net.WriteString(url)
		net.WriteString(title)
		if not target then net.Broadcast() else net.Send(target) end
	end)
end

function wmcp.StopFor(target, opts)
	net.Start("wmcp_gstop")
	if not target then net.Broadcast() else net.Send(target) end
end