import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;

UCLASS(NotBlueprintable, meta = ("SickleTrailActivation"))
class UAnimNotify_SickleTrailActivation : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SickleTrailActivation";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		auto SickleComponent = USickleComponent::Get(MeshComp.GetOwner());
		if(SickleComponent != nullptr)
		{
			SickleComponent.EnableTrail(MeshComp);
		}
		return true;
	}


	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		auto SickleComponent = USickleComponent::Get(MeshComp.GetOwner());
		if(SickleComponent != nullptr)
		{
			SickleComponent.DisableTrail(MeshComp);
		}
		return true;
	}
};