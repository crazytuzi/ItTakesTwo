import Rice.TemporalLog.TemporalLogComponent;

class UCapabilityTemporalLogAction : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		UHazeCapabilityComponent Comp = UHazeCapabilityComponent::Get(Actor);
		if (Comp == nullptr)
			return;

		auto ComponentLog = Log.LogObject(n"Components", Comp, bLogProperties = false);
		ComponentLog.Values.Add(n"ActiveSheet", Comp.ActiveSheetName);
		Comp.GetAttributeDebugValues(ComponentLog.Values);

		for (UHazeCapability Capability : Comp.GetCapabilities())
		{
			FLinearColor StatusColor = FLinearColor::Gray;
			FString Summary;

			if (Capability.IsActive())
			{
				StatusColor = FLinearColor::Green;
				Summary = "(Active)";
			}
			else if (Capability.IsBlocked())
			{
				StatusColor = FLinearColor::Red;
				Summary = "(Blocked)";
			}

			auto CapabilityLog = Log.LogObject(FName("Capabilities:"+Capability.CapabilityDebugCategory), Capability, Color = StatusColor);
			CapabilityLog.Summary = Summary;

			FString Str = Capability.GetDebugString();
			if (Str.Len() != 0)
				CapabilityLog.Values.Add(n"Str", Str);

			CapabilityLog.Values.Add(n"State", Summary);

			Capability.DebugDescribeBlockers(CapabilityLog.Values);
		}
	}
};