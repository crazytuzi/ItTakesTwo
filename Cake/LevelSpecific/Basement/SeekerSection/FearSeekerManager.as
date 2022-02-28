import Cake.LevelSpecific.Basement.SeekerSection.FearSeeker;
import Cake.LevelSpecific.Basement.RespawnBubble.BasementRespawnBubble;

class AFearSeekerManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY()
	APostProcessVolume PostProcessVolume;

	UPROPERTY()
	ABasementRespawnBubble RespawnBubble;

	UPROPERTY()
	UNiagaraSystem SpottedEffect;

	TArray<AFearSeeker> FearSeekers;

	bool bPlayersSpotted = false;

	float CurrentPostProcessWeight = 0.f;

	UNiagaraComponent SpottedEffectComp;

	float CurrentDamageSpeed = 0.25f;
	float DefaultDamageSpeed = 0.25f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(FearSeekers);
		for (AFearSeeker CurFearSeeker : FearSeekers)
		{
			CurFearSeeker.OnSpottedByFearSeeker.AddUFunction(this, n"PlayersSpotted");
			CurFearSeeker.OnUnspottedByFearSeeker.AddUFunction(this, n"PlayersUnspotted");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayersSpotted(float DamageSpeed)
	{
		bPlayersSpotted = true;
		CurrentDamageSpeed = DamageSpeed;

		if (SpottedEffectComp != nullptr)
		{
			SpottedEffectComp.SetHiddenInGame(false);
			SpottedEffectComp.Activate(false);
			return;
		}

		SpottedEffectComp = Niagara::SpawnSystemAttached(SpottedEffect, GetActiveParentBlobActor().RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	UFUNCTION()
	void PlayersUnspotted()
	{
		bPlayersSpotted = false;
		if (SpottedEffect != nullptr)
		{
			if (SpottedEffectComp != nullptr)
			{
				SpottedEffectComp.Deactivate();
				SpottedEffectComp.SetHiddenInGame(true);
			}
		}

		CurrentDamageSpeed = DefaultDamageSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (PostProcessVolume != nullptr)
		{
			float TargetPostProcessWeight = 0.f;
			if (bPlayersSpotted)
			{
				TargetPostProcessWeight = 1.f;
			}
			else
			{
				TargetPostProcessWeight = 0.f;
			}

			CurrentPostProcessWeight = FMath::FInterpConstantTo(CurrentPostProcessWeight, TargetPostProcessWeight, DeltaTime, 0.25f);
			PostProcessVolume.BlendWeight = CurrentPostProcessWeight;

			if (CurrentPostProcessWeight >= 1.f)
			{
				RespawnBubble.Activate();
			}
		}
	}
}