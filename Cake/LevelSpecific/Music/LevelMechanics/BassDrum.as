UCLASS(Abstract)
class ABassDrum : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BassDrumMesh;

	UPROPERTY(DefaultComponent, Attach = BassDrumMesh)
	UStaticMeshComponent FrontSkin;

	UPROPERTY(DefaultComponent, Attach = BassDrumMesh)
	UStaticMeshComponent BackSkin;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent BeatDirection;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HitByPedalTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem HitByPedalEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> PlayerCapability;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HitByPedalTimeLike.BindUpdate(this, n"UpdateHitByPedal");
		HitByPedalTimeLike.BindFinished(this, n"FinishHitByPedal");
	}

	void HitByPedal()
	{
		HitByPedalTimeLike.PlayFromStart();

		Niagara::SpawnSystemAtLocation(HitByPedalEffect, BeatDirection.WorldLocation);

		TArray<AActor> ActorsToIgnore;
		TArray<FHitResult> Hits;
		FVector TraceLoc = BeatDirection.WorldLocation + (BeatDirection.ForwardVector * 300.f);
		Trace::CapsuleTraceMultiAllHitsByChannel(TraceLoc, TraceLoc, FQuat(BeatDirection.WorldRotation + FRotator(90.f, 0.f, 0.f)), 1000.f, 1200.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, Hits);

		for (FHitResult CurHit : Hits)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurHit.Actor);

			if (Player != nullptr)
			{
				Player.AddImpulse(BeatDirection.ForwardVector * 5000.f + FVector(0.f, 0.f, 3000.f));
			}
		}
	}

	UFUNCTION()
	void UpdateHitByPedal(float CurValue)
	{
		float CurFrontSkinScale = FMath::Lerp(5.f, 10.f, CurValue);
		FrontSkin.SetRelativeScale3D(FVector(5.f, 5.f, CurFrontSkinScale));

		float CurBackSkinScale = FMath::Lerp(5.f, 0.25f, CurValue);
		BackSkin.SetRelativeScale3D(FVector(5.f, 5.f, CurBackSkinScale));
	}

	UFUNCTION()
	void FinishHitByPedal()
	{

	}
}