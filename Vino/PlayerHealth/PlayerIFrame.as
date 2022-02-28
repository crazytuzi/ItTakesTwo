
import Vino.PlayerHealth.PlayerHealthComponent;

UCLASS(meta = ("SetPlayerIFrame"))
class UAnimNotify_SetPlayerIFrame : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
 		return "Player I-Frame";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyTick(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float FrameDeltaTime) const
	{
		auto HealthComp = UPlayerHealthComponent::Get(MeshComp.Owner);
		if(HealthComp != nullptr)
		{
			HealthComp.SetIFrameActive();
		}
		return true;
	}
};
