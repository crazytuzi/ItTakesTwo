import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkActor;

event void FClockTownPigEvent();

class ClockTownPigOnTrack : ATownsfolkActor
{
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh SmallPlatform;
	UPROPERTY(EditDefaultsOnly)
	UStaticMesh BigPlatform;

	UPROPERTY()
	bool bIsBig = true;

	UPROPERTY(NotEditable)
	int CurrentSplineIndex = 0;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotatePigTimeLike;
	UPROPERTY()
	float TargetYaw = 90.f;
	float StartYaw = 0.f;

	UPROPERTY()
	FClockTownPigEvent OnPigReadyToBeFed;
	UPROPERTY()
	FClockTownPigEvent OnBigPigRevealed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetPigSize(bIsBig);

		// SkelMesh.SetHiddenInGame(!bIsBig);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnReachedEndOfSpline.AddUFunction(this, n"ReachedEndOfSpline");

		RotatePigTimeLike.BindUpdate(this, n"UpdateRotatePig");
		RotatePigTimeLike.BindFinished(this, n"FinishRotatePig");
	}

	UFUNCTION()
	void RotatePig(bool bReverse = false)
	{
		if (!bReverse)
		{
			StopMoving();
			StartYaw = ActorRotation.Yaw;
			RotatePigTimeLike.PlayFromStart();
		}
		else
		{
			RotatePigTimeLike.ReverseFromEnd();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRotatePig(float CurValue)
	{
		float CurYaw = FMath::Lerp(StartYaw, StartYaw + TargetYaw, CurValue);
		SkelMesh.SetRelativeRotation(FRotator(0.f, CurYaw, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRotatePig()
	{
		if (RotatePigTimeLike.IsReversed())
		{
			OnBigPigRevealed.Broadcast();
		}
		else
		{
			OnPigReadyToBeFed.Broadcast();
		}
	}

	UFUNCTION()
	void ReachedEndOfSpline(ATownsfolkActor Actor)
	{
		CurrentSplineIndex++;
		BP_ReachedEndOfSpline();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedEndOfSpline() {}

	UFUNCTION()
	void ShowPig()
	{
		SkelMesh.SetHiddenInGame(false);
	}

	UFUNCTION()
	void SetPigSize(bool bBig)
	{
		bIsBig = bBig;
		if (bIsBig)
		{
			SkelMesh.SetRelativeScale3D(FVector::OneVector);
			Platform.SetStaticMesh(BigPlatform);
			PlayerCollision.SetCapsuleSize(40.f, 110.f);
			PlayerCollision.SetRelativeLocation(FVector(0.f, 0.f, 130.f));
		}
		else
		{
			SkelMesh.SetRelativeScale3D(FVector(0.65f, 0.65f, 0.65f));
			Platform.SetStaticMesh(SmallPlatform);
			PlayerCollision.SetCapsuleSize(30.f, 55.f);
			PlayerCollision.SetRelativeLocation(FVector(0.f, 0.f, 95.f));
		}
	}
}