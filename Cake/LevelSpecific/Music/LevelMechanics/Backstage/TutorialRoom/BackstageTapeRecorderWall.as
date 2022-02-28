
event void FOnOpenCassetteTape();

class ABackstageTapeRecorderWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RootCompSub;
	UPROPERTY(DefaultComponent, Attach = RootCompSub)
	UHazeSkeletalMeshComponentBase Mesh;
	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WiggleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BandCutOffAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FallAudioEvent;

	FHazeAcceleratedFloat AccelerateFloat;
	FHazeAcceleratedFloat AccelerateFloatX;
	float SongOfLifeRotateTargetValue = 0.5f;
	bool bWiggle = false;
	bool bFallDown = false;
	bool bSongOfLifeActive = false;

	bool bFirstFallDownSeq = true;
	bool bSecondFallDownSeq = false;
	bool bThirdFallDownSeq = false;
	bool bBandsCutOff = false;
	bool bLeftBandCutOff = false;
	bool bRightBandCutOff = false;
	private bool bIsOpen = false;

	UPROPERTY()
	FOnOpenCassetteTape OnOpenCassetteTape;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComponent.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"TapeBase"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, false);
		BoxComponent.AddLocalOffset(FVector(105, 0, 1250));
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds){}

	UFUNCTION()
	void SongOfLifeStart()
	{
		bSongOfLifeActive = true;
	}
	UFUNCTION()
	void SongOfLifeStop()
	{
		bSongOfLifeActive = false;
	}

	UFUNCTION()
	void BandsCutOff()
	{
		bBandsCutOff = true;
	}
	UFUNCTION()
	void LeftBandCutOff()
	{
		bLeftBandCutOff = true;
		UHazeAkComponent::HazePostEventFireForget(BandCutOffAudioEvent, this.GetActorTransform());
	}
	UFUNCTION()
	void RightBandCutOff()
	{
		bRightBandCutOff = true;
		UHazeAkComponent::HazePostEventFireForget(BandCutOffAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void StartWigglePlatform()
	{
		bWiggle = true;
		System::SetTimer(this, n"StopWiggle", 0.1f, false);
		UHazeAkComponent::HazePostEventFireForget(WiggleAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void StopWiggle()
	{
		bWiggle = false;
	}

	UFUNCTION(NetFunction)
	void StartFallDown()
	{
		bFallDown = true;
		UHazeAkComponent::HazePostEventFireForget(FallAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void OpenCasseteTape()
	{
		if(!HasControl())
			return;

		if(bIsOpen)
			return;

		NetOpenCasseteTape();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetOpenCasseteTape()
	{
		bIsOpen = true;
		OnOpenCassetteTape.Broadcast();
	}
}
