import Rice.TemporalLog.TemporalLogComponent;

class UCharacterPositionTemporalLogAction : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		AHazeCharacter Character = Cast<AHazeCharacter>(Actor);
		if (Character == nullptr)
			return;

		auto Capsule = Character.CapsuleComponent;
		if (Capsule == nullptr)
			return;

		UTemporalLogObject CapsuleLog = Log.LogObject(n"Components", Capsule, bLogProperties = false);
		CapsuleLog.LogCapsule(n"Position",
			Capsule.WorldLocation, Capsule.ScaledCapsuleHalfHeight, Capsule.ScaledCapsuleRadius,
			Rotation = Capsule.WorldRotation,
			Color = FLinearColor::Blue,
			bDrawByDefault = true);
	}
};