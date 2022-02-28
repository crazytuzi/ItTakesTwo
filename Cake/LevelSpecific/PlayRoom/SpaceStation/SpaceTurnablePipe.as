import Peanuts.Spline.SplineComponent;

UCLASS(Abstract)
class ASpaceTurnablePipe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BaseRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseRoot)
	USceneComponent PipeRoot;

	UPROPERTY(DefaultComponent, Attach = PipeRoot)
	UStaticMeshComponent PipeMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PipeRotateAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotatePipeTimeLike;
	default RotatePipeTimeLike.Duration = 0.2f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike LockPipeTimeLike;
	default LockPipeTimeLike.Duration = 0.1f;

	UPROPERTY()
	int CurrentIndex = 0;

	float BaseStartRot = 0.f;
	float PipeStartRot = 0.f;
	UPROPERTY(NotEditable)
	bool bPipeLocked = false;

	bool bPipeShouldBeLocked = false;

	bool bRotating = false;

	FVector PipeDefaultLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotatePipeTimeLike.BindUpdate(this, n"UpdateRotatePipe");
		RotatePipeTimeLike.BindFinished(this, n"FinishRotatePipe");

		LockPipeTimeLike.BindUpdate(this, n"UpdateLockPipe");
		LockPipeTimeLike.BindFinished(this, n"FinishLockPipe");

		PipeDefaultLoc = PipeRoot.WorldLocation;
	}

	UFUNCTION(NetFunction)
	void NetRotatePipe(bool bLocked)
	{
		bPipeLocked = bLocked;
		if (bPipeLocked)
			return;

		bRotating = true;
		PipeStartRot = PipeRoot.RelativeRotation.Yaw;

		BaseStartRot = BaseRoot.RelativeRotation.Yaw;
		RotatePipeTimeLike.PlayFromStart();

		CurrentIndex++;
		if (CurrentIndex >= 4)
			CurrentIndex = 0;

		UHazeAkComponent::HazePostEventFireForget(PipeRotateAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRotatePipe(float CurValue)
	{
		float CurBaseRot = FMath::Lerp(BaseStartRot, BaseStartRot + 90.f, CurValue);
		BaseRoot.SetRelativeRotation(FRotator(0.f, CurBaseRot, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRotatePipe()
	{
		bRotating = false;

		if (bPipeShouldBeLocked)
		{
			LockPipe();
		}
		else
		{
			UnlockPipe();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateLockPipe(float CurValue)
	{
		// FVector CurLoc = FMath::Lerp(PipeDefaultLoc, PipeDefaultLoc + FVector(0.f, 0.f, 100.f), CurValue);
		// PipeRoot.SetWorldLocation(CurLoc);
	}

	UFUNCTION(BlueprintEvent)
	void BP_LockPipe() {}

	UFUNCTION(BlueprintEvent)
	void BP_UnlockPipe() {}

	UFUNCTION(NotBlueprintCallable)
	void FinishLockPipe()
	{

	}

	UFUNCTION()
	void LockPipe()
	{
		bPipeShouldBeLocked = true;
		
		if (!bRotating)
		{
			bPipeLocked = true;
			LockPipeTimeLike.Play();
			BP_LockPipe();
		}
	}

	UFUNCTION()
	void UnlockPipe()
	{
		bPipeShouldBeLocked = false;

		if (!bRotating)
		{
			bPipeLocked = false;
			LockPipeTimeLike.Reverse();
			BP_UnlockPipe();
		}
	}
}