event void FOnFireExtinguished();

class ARegeneratingClockTownFire : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FireRoot;

	UPROPERTY(DefaultComponent, Attach = FireRoot)
	UStaticMeshComponent FireMesh;

	UPROPERTY()
	FOnFireExtinguished OnFireExtinguished;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ExtinguishTimeLike;
	default ExtinguishTimeLike.Duration = 1.f;

	UPROPERTY(NotEditable)
	bool bExtinguished = false;
	bool bRotating = true;
	bool bPermanentlyExtinguished = false;
	
	float RotationOffset;
	float RotationSpeed;

	float TimeUntilReset = 3.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotationSpeed = FMath::RandRange(8.f, 12.f);
		RotationOffset = FMath::RandRange(1.f, 10.f);

		ExtinguishTimeLike.BindUpdate(this, n"UpdateExtinguish");
		ExtinguishTimeLike.BindFinished(this, n"FinishExtinguish");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bRotating)
		{
			float Rot = System::GetGameTimeInSeconds() * RotationSpeed;
			Rot += RotationOffset;
			Rot = FMath::Sin(Rot);
			Rot *= RotationOffset;

			FireMesh.SetRelativeRotation(FRotator(Rot, 0.f, 0.f));
		}
	}

	UFUNCTION()
	void Extinguish()
	{
		ExtinguishTimeLike.PlayFromStart();
		bExtinguished = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateExtinguish(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, EndLocation, CurValue);
		FireRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishExtinguish()
	{
		if (bExtinguished)
			System::SetTimer(this, n"ResetFire", TimeUntilReset, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void ResetFire()
	{
		if (bPermanentlyExtinguished)
			return;

		if (!bExtinguished)
			return;

		ExtinguishTimeLike.ReverseFromEnd();
		bExtinguished = false;
	}

	UFUNCTION()
	void PermanentlyExtinguish()
	{
		bPermanentlyExtinguished = true;
	}
}