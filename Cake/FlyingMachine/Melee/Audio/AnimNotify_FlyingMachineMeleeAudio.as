import Cake.FlyingMachine.Melee.Audio.FlyingMachineMeleePlayerAudioCapability;

UCLASS(NotBlueprintable, meta = (DisplayName = "Flying Machine Melee Audio"))
class UAnimNotify_FlyingMachineMeleeAudio : UAnimNotify
{
	UPROPERTY()
	EHazeMeleeAudioAction ActionType;		

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		auto HazeOwner = Cast<AHazeActor>(MeshComp.Owner);
		if(HazeOwner == nullptr)
			return false;

		HazeOwner.SetCapabilityAttributeNumber(n"MeleeAudio", int(ActionType));

		return true;
	}
	
}