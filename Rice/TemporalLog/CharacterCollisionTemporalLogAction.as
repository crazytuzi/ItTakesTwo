import Rice.TemporalLog.TemporalLogComponent;
import Peanuts.Movement.MovementDebugDataComponent;

class UCharacterCollisionTemporalLogAction : UTemporalLogAction
{
	UFUNCTION()
	void OnTemporalCallback(AHazeActor Actor, UTemporalLogFrame Frame) const
	{
		auto DataComp = UMovementDebugDataComponent::Get(Actor);
		if (DataComp == nullptr)
			return;

		DataComp.RerunFrame(Frame.FrameNumber);
	}

	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		auto DataComp = UMovementDebugDataComponent::Get(Actor);
		if (DataComp == nullptr)
			return;

		UTemporalLogObject CollisionLog = Log.LogObject(n"Collisions", DataComp, bLogProperties = false);

		FTemporalLogCallbackFunction CallbackEvent;
		CallbackEvent.AddUFunction(this, n"OnTemporalCallback");
		CollisionLog.SetCallback("Rerun Frame", CallbackEvent);

		for (auto& Event : DataComp.EventData)
		{
			for (auto& EventEntry : Event.GetValue().Events)
			{
				const FVisualData& Data = EventEntry.VisualData;

				switch(EventEntry.Type)
				{
					case EMovementVisualizationType::Line:
						CollisionLog.LogLine(Event.Key, Data.Location, Data.ExtraData, Data.Color, false, Data.Thickness, Data.bAddAsText);
					break;
					case EMovementVisualizationType::Capsule:
						CollisionLog.LogCapsule(Event.Key, Data.Location, Data.ExtraData.Z, Data.ExtraData.X, Data.Color, false, Data.Thickness, Data.Rotation);
					break;
					case EMovementVisualizationType::Sphere:
						CollisionLog.LogSphere(Event.Key, Data.Location, Data.ExtraData.X, Data.Color, false, Data.Thickness);
					break;
					case EMovementVisualizationType::Box:
						CollisionLog.LogBox(Event.Key, Data.Location, Data.ExtraData, Data.Color, false, Data.Thickness, Data.Rotation);
					break;
					case EMovementVisualizationType::Message:
						CollisionLog.LogValue(Event.Key, EventEntry.StringValue);
					break;
					default:
				}
			}
		}
	}
};
