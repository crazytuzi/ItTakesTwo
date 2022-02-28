import Vino.Audio.AudioActors.HazeAmbientSound;


class APendulumActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent AudioLocation;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bShouldUpdatePhysicsVolume = false;
	default Mesh.CastShadow = false;

	UPROPERTY(Category = "Pendulum")
	float DelayUntilStart;

	UPROPERTY(Category = "Pendulum")
	float RotationAmount;

	UPROPERTY(Category = "Pendulum")
	float SecondsForFullSwing;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent PlayFromStartAudio;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ReverseFromEndAudio;
	
	UPROPERTY(EditConst, Category = "Audio")
	UHazeAkComponent AkComponent;

	UPROPERTY(EditConst, Category = "Pendulum")
	float PlayRate = 1.f;

	float LastUpdateTime = 0;
	float MovementTime = 0;
	bool bMovingForward = true;
	float ForcedUpdateToGameTime = 0;
	float RandomTimeUpdate = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AkComponent = UHazeAkComponent::Get(this);
		if(AkComponent != nullptr)
			AkComponent.AttachToComponent(AudioLocation);

		if(SecondsForFullSwing > 0)
			PlayRate = 2.f / SecondsForFullSwing;
		else
			PlayRate = 1.f;
	}

	UFUNCTION(BlueprintPure)
	bool IsReversed() const
	{
		return !bMovingForward;
	}

	UFUNCTION()
	void PlaySound(UAkAudioEvent Audio)
	{
		if(Audio == nullptr)
			return;

		if(AkComponent == nullptr)
			UHazeAkComponent::HazePostEventFireForget(Audio, AudioLocation.GetWorldTransform());
		else
			AkComponent.HazePostEvent(Audio);		
	}
}


