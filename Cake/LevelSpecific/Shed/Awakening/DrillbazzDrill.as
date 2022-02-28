class ADrillBazzDrill : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	FTransform StartTransform;

	UPROPERTY()
	FHazeTimeLike Timelike;

	UPROPERTY(Meta = (MakeEditWidget))
	FTransform DesiredTransform;

	UPROPERTY()
	UAkAudioEvent FwdAudioEvent;

	UPROPERTY()
	UAkAudioEvent BwdAudioEvent;

	const float FwdAudioPosition = 0.0f;
	const float BwdAudioPosition = 0.625f; // 2.5s into a 4s duration
	bool bFwdAudioTriggered = false;
	bool bBwdAudioTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Timelike.BindUpdate(this, n"DrillTick");
		Timelike.BindFinished(this, n"DrillFinished");
		Timelike.PlayFromStart();

		StartTransform = Mesh.RelativeTransform;
	}

	UFUNCTION(NotBlueprintCallable)
	void DrillTick(float CurValue)
	{
		FTransform BlendedTransform;
		BlendedTransform.Blend(StartTransform, DesiredTransform, CurValue);

		Mesh.RelativeTransform = BlendedTransform;

		float Position = Timelike.Position;
		if (!bFwdAudioTriggered && Position > FwdAudioPosition)
		{
			UHazeAkComponent::HazePostEventFireForget(FwdAudioEvent, GetActorTransform());
			bFwdAudioTriggered = true;
		}
		if (!bBwdAudioTriggered && Position > BwdAudioPosition)
		{
			UHazeAkComponent::HazePostEventFireForget(BwdAudioEvent, GetActorTransform());
			bBwdAudioTriggered = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void DrillFinished()
	{
		// Reset variables used in timelike loop
		bFwdAudioTriggered = false;
		bBwdAudioTriggered = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
}