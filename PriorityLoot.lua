PriorityLoot = LibStub("AceAddon-3.0"):NewAddon("PriorityLoot", "AceConsole-3.0", "AceEvent-3.0" );

function PriorityLoot:OnInitialize()
		-- Called when the addon is loaded

		-- Print a message to the chat frame
		self:Print("OnInitialize Event Fired: Hello")
end

function PriorityLoot:OnEnable()
		-- Called when the addon is enabled

		-- Print a message to the chat frame
		self:Print("OnEnable Event Fired: Hello, again ;)")
end

function PriorityLoot:OnDisable()
		-- Called when the addon is disabled
end
