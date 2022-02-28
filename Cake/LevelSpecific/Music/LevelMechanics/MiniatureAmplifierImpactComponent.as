
class UMiniatureAmplifierContainerComponent : UActorComponent
{
	TArray<UMiniatureAmplifierImpactComponent> ImpactCollection;
}

void GetAllMiniatureAmplifierImpacts(TArray<UMiniatureAmplifierImpactComponent>& OutImpacts)
{
	OutImpacts = UMiniatureAmplifierContainerComponent::GetOrCreate(Game::GetCody()).ImpactCollection;
}

struct FAmplifierImpactInfo
{
	UPROPERTY()
	FVector Origin;
	UPROPERTY()
	FVector ImpactPoint;
	UPROPERTY()
	FVector DirectionFromInstigator;
	UPROPERTY()
	AHazeActor Instigator;
}

event void FOnAmplifierImpact(FAmplifierImpactInfo HitInfo);

class UMiniatureAmplifierImpactComponent : UActorComponent
{
	UPROPERTY()
	FOnAmplifierImpact OnImpact;

	UPROPERTY()
	bool bUnlimitedImpacts = false;

	UPROPERTY(meta = (EditCondition = "!bUnlimitedImpacts", EditConditionHides, ClampMin = 1))
	int ImpactCountMax = 1;

	int ImpactCountTotal = 0;

	void Impact(FAmplifierImpactInfo HitInfo)
	{
		if(!IsValidImpact())
			return;

		ImpactCountTotal++;
		OnImpact.Broadcast(HitInfo);
	}

	bool IsValidImpact() const
	{
		if(bUnlimitedImpacts)
			return true;

		return ImpactCountTotal < ImpactCountMax;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UMiniatureAmplifierContainerComponent MiniatureAmplifierContainer = UMiniatureAmplifierContainerComponent::GetOrCreate(Game::GetCody());

		if(MiniatureAmplifierContainer.ImpactCollection.Num() == 0)
			Reset::RegisterPersistentComponent(MiniatureAmplifierContainer);

		MiniatureAmplifierContainer.ImpactCollection.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UMiniatureAmplifierContainerComponent MiniatureAmplifierContainer = UMiniatureAmplifierContainerComponent::GetOrCreate(Game::GetCody());
		bool bHadReactions = MiniatureAmplifierContainer.ImpactCollection.Num() != 0;
		MiniatureAmplifierContainer.ImpactCollection.Remove(this);

		if (bHadReactions && MiniatureAmplifierContainer.ImpactCollection.Num() == 0)
			Reset::UnregisterPersistentComponent(MiniatureAmplifierContainer);
	}
}
