import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomLightStripComponent;

class ALightRoomFoldingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	ALightRoomActivationPoints ActivationPoint;

	UPROPERTY()
	TArray<APointLight> ConnectedPointLights;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformMoveUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformMoveDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformIsUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformIsDownAudioEvent;

	UPROPERTY()
	FHazeTimeLike RotatePlatformTimeline;
	default RotatePlatformTimeline.bLoop = false;
	default RotatePlatformTimeline.Duration = .75f;

	UPROPERTY()
	FHazeTimeLike LerpHingeLightsTimeline;
	default LerpHingeLightsTimeline.Duration = 0.5f;

	UPROPERTY()
	FRotator StartingRot = FRotator::ZeroRotator;
	
	UPROPERTY()
	FRotator TargetRot = FRotator(90.f, 0.f, 0.f);

	UPROPERTY()
	FLinearColor HingeUnlitColor;
	
	UPROPERTY()
	FLinearColor HingeLitColor;
	
	bool bShouldRotateActor = false;

	bool bPlatformIsUp = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationPoint.ActivationPointActivated.AddUFunction(this, n"ActivationPointActivated");
		RotatePlatformTimeline.BindUpdate(this, n"RotatePlatformTimelineUpdate");
		LerpHingeLightsTimeline.BindUpdate(this, n"LerpHingeLightsTimelineUpdate");
		Mesh.SetColorParameterValueOnMaterialIndex(2, n"Emissive Tint", HingeUnlitColor);

		for (auto Light : ConnectedPointLights)
		{
			Light.LightComponent.SetIntensity(0.f);
		}
	}

	UFUNCTION()
	void ActivationPointActivated(bool bActivated)
	{
		bActivated ? RotatePlatformTimeline.Play() : RotatePlatformTimeline.Reverse();
		bActivated ? LerpHingeLightsTimeline.Play() : LerpHingeLightsTimeline.Reverse();

		if(bActivated)
			UHazeAkComponent::HazePostEventFireForget(PlatformMoveUpAudioEvent, this.GetActorTransform());
		else if(!bActivated)
			UHazeAkComponent::HazePostEventFireForget(PlatformMoveDownAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void RotatePlatformTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRot, TargetRot, CurrentValue));

		if(bPlatformIsUp && CurrentValue == 0.0f)
		{
			UHazeAkComponent::HazePostEventFireForget(PlatformIsDownAudioEvent, this.GetActorTransform());
			bPlatformIsUp = false;
		}
		if(!bPlatformIsUp && CurrentValue == 1.0f)
		{
			UHazeAkComponent::HazePostEventFireForget(PlatformIsUpAudioEvent, this.GetActorTransform());
			bPlatformIsUp = true;
		}
	}

	UFUNCTION()
	void LerpHingeLightsTimelineUpdate(float CurrentValue)
	{
		Mesh.SetColorParameterValueOnMaterialIndex(2, n"Emissive Tint", FMath::Lerp(HingeUnlitColor, HingeLitColor, CurrentValue));

		for (auto Light : ConnectedPointLights)
		{
			Light.LightComponent.SetIntensity(FMath::Lerp(0.f, 20.f, CurrentValue));
		}
	}
}