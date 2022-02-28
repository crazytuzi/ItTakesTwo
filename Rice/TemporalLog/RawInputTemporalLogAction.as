import Rice.TemporalLog.TemporalLogComponent;

class URawInputTemporalLogAction : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		UHazeInputComponent Comp = UHazeInputComponent::Get(Actor);
		if (Comp == nullptr)
			return;

	#if EDITOR
		auto ComponentLog = Log.LogObject(n"Components", Comp, bLogProperties = false);

		for (auto It : Comp.RawAxisInputValues)
		{
			float Value = It.Value;
			float Time = -1.f;

			Comp.RawAxisTimeValues.Find(It.Key, Time);
			ComponentLog.LogValue(It.Key, ""+Value+" @ GameTime "+Time);
		}
	#endif
	}
};