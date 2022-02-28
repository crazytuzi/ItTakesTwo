import Rice.TemporalLog.TemporalLogComponent;

class UAnimationTemporalLogAction : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		UHazeSkeletalMeshComponentBase Comp = UHazeSkeletalMeshComponentBase::Get(Actor);
		if (Comp == nullptr)
			return;

		auto ComponentLog = Log.LogObject(n"Components", Comp, bLogProperties = false);

		float Position = 0.f;
		FVector2D BlendValues;
		UAnimationAsset Animation = AnimationDebug::GetRawPlayingAnimation(Actor, Position, BlendValues);
		if (Animation != nullptr)
		{
			ComponentLog.LogAnimation(n"Raw Animation (UNBLENDED)",
				Comp.WorldLocation, Comp.WorldRotation, Animation, Position,
				BlendValues = BlendValues, bDrawByDefault = true);
		}
	}
};