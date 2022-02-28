UCLASS(Abstract)
class ASpacePinballToggleableWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WallRoot;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	UStaticMeshComponent WallMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WallMoveAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveWallTimeLike;

	UPROPERTY()
	bool bExposed = true;

	UPROPERTY()
	bool bCanBeToggled = true;

	FVector TopLoc = FVector::ZeroVector;
	FVector BottomLoc = FVector(0.f, 0.f, -100.f);

	FVector StartLoc;
	FVector EndLoc;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bExposed)
		{
			WallRoot.SetRelativeLocation(TopLoc);
		}
		else
		{
			WallRoot.SetRelativeLocation(BottomLoc);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveWallTimeLike.SetPlayRate(4.f);
		MoveWallTimeLike.BindUpdate(this, n"UpdateMoveWall");
		MoveWallTimeLike.BindFinished(this, n"FinishMoveWall");
	}

	UFUNCTION()
	void MoveWall()
	{
		if (!bCanBeToggled)
			return;

		if (bExposed)
		{
			StartLoc = TopLoc;
			EndLoc = BottomLoc;
		}
		else
		{
			StartLoc = BottomLoc;
			EndLoc = TopLoc;
		}

		MoveWallTimeLike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(WallMoveAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveWall(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLoc, EndLoc, CurValue);
		WallRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveWall()
	{
		bExposed = !bExposed;
	}
}