USTRUCT()
struct FCameraShotFov
{
	UPROPERTY()
	float FovValue;

	UPROPERTY()
	float FovBlendTime;
}

USTRUCT()
struct FCameraShot
{
	UPROPERTY()
	FHazeMinMax ValidTimeStamp;

	UPROPERTY()
	FHazePointOfInterest PointOfInterest;

	UPROPERTY()
	FCameraShotFov ShotFov;
}

class UCameraShotTimedSequenceComponent : UActorComponent
{
	AHazePlayerCharacter PlayerOwner;
	TArray<FCameraShot> ShotSequence;

	FCameraShot CurrentShot;

	float SequenceDuration;
	float ElapsedTime;

	bool bTickIsActive;
	bool bShotIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bTickIsActive)
			return;

		ElapsedTime += DeltaTime;

		// Check if 
		if(ElapsedTime >= SequenceDuration || ShotSequence.Num() == 0)
		{
			FinishSequence();
			return;
		}

		if(!bShotIsActive)
		{
			// Activate shot if we're inside time stamp
			if(ShotSequence[0].ValidTimeStamp.IsInsideRange(ElapsedTime, true, false))
				ActivateShot(ShotSequence[0]);
		}
		else
		{
			// Deactivate shot if it's no longer within time stamp range
			if(!CurrentShot.ValidTimeStamp.IsInsideRange(ElapsedTime, true, false))
				DeactivateCurrentShot();
		}
	}

	void Initialize(TArray<FCameraShot>& CameraShotSequence)
	{
		if(CameraShotSequence.Num() == 0)
		{
			Warning("UCameraShotSequenceComponent::Initialize() - Camera shot sequence is empty!");
			return;
		}
		
		ShotSequence = CameraShotSequence;
		SequenceDuration = CameraShotSequence[CameraShotSequence.Num() - 1].ValidTimeStamp.MaxValue;

		ElapsedTime = 0.f;
		bShotIsActive = false;
	}

	void Play()
	{
		if(ShotSequence.Num() == 0)
		{
			Warning("UCameraShotSequenceComponent::Play() - Shot sequence is empty, did you forget to initialize?");
			return;
		}

		bTickIsActive = true;
	}

	private void ActivateShot(FCameraShot CameraShot)
	{
		bShotIsActive = true;
		CurrentShot = CameraShot;

		PlayerOwner.ApplyPointOfInterest(CurrentShot.PointOfInterest, this, EHazeCameraPriority::Maximum);
		PlayerOwner.ApplyFieldOfView(CurrentShot.ShotFov.FovValue, CurrentShot.ShotFov.FovBlendTime, this, EHazeCameraPriority::Maximum);
	}

	private void DeactivateCurrentShot()
	{
		bShotIsActive = false;

		PlayerOwner.ClearPointOfInterestByInstigator(this);
		PlayerOwner.ClearFieldOfViewByInstigator(this, CurrentShot.ShotFov.FovBlendTime);

		ShotSequence.RemoveAt(0);
		CurrentShot = FCameraShot();
	}

	private void FinishSequence()
	{
		if(bShotIsActive)
			DeactivateCurrentShot();
		
		bTickIsActive = false;
	}
}