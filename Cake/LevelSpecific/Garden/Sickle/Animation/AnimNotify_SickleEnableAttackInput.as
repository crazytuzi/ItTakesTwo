
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;

UCLASS(NotBlueprintable, meta = ("SickleEnableAttackInput"))
class UAnimNotify_SickleEnableAttackInput : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SickleEnableAttackInput";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(MeshComp.GetOwner());
		if (Player == nullptr)
			return false;

		auto SickleComp = USickleComponent::Get(Player);
		if (SickleComp == nullptr)
			return false;

		SickleComp.bCanActiveNextAttack = true;
		return true;
	}
};