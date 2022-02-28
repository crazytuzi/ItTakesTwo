
class AFrogPondFountainBacktrackBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationPointComp;

	UPROPERTY(DefaultComponent, Attach = RotationPointComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FHazeTimeLike RotationTimeLike;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ABlockingVolume LinkedBlockingVolume;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LidCLosingAudioEvent;

	UPROPERTY(Category = "Settings")
	float TargetPitch = 0.f;
	
	FRotator StartRot;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotationTimeLike.BindUpdate(this, n"RotationUpdate");
		StartRot = RotationPointComp.RelativeRotation;

		if(LinkedBlockingVolume != nullptr)
			LinkedBlockingVolume.SetActorEnableCollision(false);
	}

	UFUNCTION()
	void TriggerClosing()
	{
		if(LinkedBlockingVolume != nullptr)
			LinkedBlockingVolume.SetActorEnableCollision(true);

		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		RotationTimeLike.Play();
		UHazeAkComponent::HazePostEventFireForget(LidCLosingAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void RotationUpdate(float CurrentValue)
	{
		float NewPitch = FMath::Lerp(StartRot.Pitch, TargetPitch, CurrentValue);
		RotationPointComp.SetRelativeRotation(FRotator(NewPitch, StartRot.Yaw, StartRot.Roll));
	}

	UFUNCTION()
	void RotationCompleted()
	{

	}

	UFUNCTION(BlueprintCallable)
	void SetFinishedState()
	{
		RotationPointComp.SetRelativeRotation(FRotator(TargetPitch, StartRot.Yaw, StartRot.Roll));
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if(LinkedBlockingVolume != nullptr)
			LinkedBlockingVolume.SetActorEnableCollision(true);
	}
}