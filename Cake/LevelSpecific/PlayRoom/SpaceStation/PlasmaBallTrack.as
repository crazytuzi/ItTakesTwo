class APlasmaBallTrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TrackRoot;
	
	UPROPERTY(DefaultComponent, Attach = TrackRoot)
	UStaticMeshComponent TrackMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrackRotateAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotateTrackTimeLike;	

	bool bForward = true;
	float StartRotation;
	float EndRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateTrackTimeLike.BindUpdate(this, n"UpdateRotateTrack");
		RotateTrackTimeLike.BindFinished(this, n"FinishRotateTrack");
	}

	UFUNCTION()
	void RotateTrack()
	{
		if (bForward)
		{
			bForward = false;
			StartRotation = -5.f;
			EndRotation = 5.f;
		}
		else
		{
			bForward = true;
			StartRotation = 5.f;
			EndRotation = -5.f;
		}

		RotateTrackTimeLike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(TrackRotateAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRotateTrack(float CurValue)
	{
		float CurRot = FMath::Lerp(StartRotation, EndRotation, CurValue);
		TrackRoot.SetRelativeRotation(FRotator(CurRot, 0.f, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRotateTrack()
	{

	}
}