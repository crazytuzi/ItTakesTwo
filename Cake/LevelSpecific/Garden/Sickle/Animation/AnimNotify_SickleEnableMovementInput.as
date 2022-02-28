
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;

UCLASS(NotBlueprintable, meta = ("SickleEnableAttackInput"))
class UAnimNotify_SickleEnableMovementInput : UAnimNotifyState
{
	UPROPERTY()
	bool bBreakOutIfDashing = true;

	UPROPERTY()
	bool bBreakOutIfSteering = false;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SickleEnableMovementInput";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyTick(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float FrameDeltaTime) const
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.GetOwner());
		if (Player == nullptr)
			return false;
		
		auto SickleComp = USickleComponent::Get(Player);
		if (SickleComp == nullptr)
			return false;

		if(bBreakOutIfDashing)
			Player.SetCapabilityActionState(n"SickleBreakOutIfDashing", EHazeActionState::ActiveForOneFrame);

		if(bBreakOutIfSteering)
			Player.SetCapabilityActionState(n"SickleBreakOutIfSteering", EHazeActionState::ActiveForOneFrame);

		return true;
	}

};