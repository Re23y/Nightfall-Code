-- A Signal is a RemoteEvent between two systems on the same machine.
--
-- The system that owns a signal fires it and never learns who is listening.
-- Anything that cares calls connect. Neither side requires the other.

local Signal = {}

-- DECISION: a factory, not a single shared object.
-- Every module you have written so far is ONE thing that exists once -- there is one
-- GameConfig, one MatchState. Signal is the first module that is a MAKER of things:
-- each call to new() builds a fresh, independent signal with its own listeners.
-- Alternative: one global bus, Events.fire("StateChanged", x). Consequence: the name
-- becomes a string nobody checks, so a typo is silence rather than an error, and
-- nothing tells you which system owns which event.
function Signal.new()
	-- Private to this one signal, and unreachable from outside: nothing out there has
	-- a name for it. The three functions below close over it -- that is the only access.
	local listeners = {}

	local signal = {}

	-- DECISION: lowercase connect/fire, where Roblox's own events use Connect/Fire.
	-- Deliberate: capital C means a real RBXScriptSignal (and Wait, Once, etc. work),
	-- lowercase means one of ours. You can tell which you are holding at a glance.
	function signal.connect(callback)
		table.insert(listeners, callback)

		-- DECISION: connect hands back the means to undo itself.
		-- Nothing disconnects today. It is here because at L19 a system will subscribe
		-- when a ROUND starts and must stop when that round ends -- the L7 ownership
		-- rule, applied to subscriptions. Without this, every round leaves its listener
		-- behind and by round ten the signal fires ten times into dead code.
		-- Alternative: return nothing. Consequence: adding it later means editing every
		-- caller that ever connected.
		local connection = {}
		function connection.disconnect()
			local index = table.find(listeners, callback)
			if index then
				table.remove(listeners, index)
			end
		end
		return connection
	end

	-- ... means "however many arguments arrived, whatever they were". It is passed
	-- straight through to each listener untouched.
	function signal.fire(...)
		-- DECISION: task.spawn(callback, ...) rather than callback(...).
		-- Consequence 1: a listener that errors or yields cannot hurt the firer or the
		--   other listeners. MatchState.set returns immediately, always. (Measured.)
		-- Consequence 2: task.spawn runs the listener IMMEDIATELY, on a new thread --
		--   it is not "later". The listener runs before the next line of this loop.
		--   It only becomes "later" if the listener yields (task.wait, a remote call).
		--   So never rely on a listener having FINISHED when fire returns.
		--
		-- table.clone because of consequence 2: a listener really can run during this
		-- loop, and a listener that disconnects something mutates `listeners` while we
		-- are walking it -- which silently SKIPS the next one. Measured: three
		-- listeners A,B,C where A disconnects itself produced A,C. B never ran and
		-- nothing reported it. We walk a snapshot instead.
		for _, callback in table.clone(listeners) do
			task.spawn(callback, ...)
		end
	end

	return signal
end

return Signal
