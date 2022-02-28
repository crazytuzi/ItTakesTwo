import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomLightStripComponent;

class ALightRoomRotatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HingeMeshBase;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HingeMesh;

	UPROPERTY()
	ALightRoomActivationPoints ActivationPoint;

	UPROPERTY()
	TArray<APointLight> ConnectedPointLights;

	UPROPERTY()
	FHazeTimeLike LerpHingeLightsTimeline;
	default LerpHingeLightsTimeline.Duration = 0.5f;

	UPROPERTY()
	FLinearColor HingeUnlitColor;
	
	UPROPERTY()
	FLinearColor HingeLitColor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrussMoveUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrussMoveDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrussIsUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrussIsDownAudioEvent;

	UPROPERTY()
	FHazeTimeLike RotatePlatformTimeline;
	default RotatePlatformTimeline.bLoop = false;
	default RotatePlatformTimeline.Duration = 1.5f;

	UPROPERTY()
	bool bShowTargetState = false;

	UPROPERTY()
	FRotator StartingRot = FRotator::ZeroRotator;
	
	UPROPERTY()
	FRotator TargetRot = FRotator(0.f, 90.f, 0.f);
	
	bool bShouldRotateActor = false;

	bool bTrussIsUp = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationPoint.ActivationPointActivated.AddUFunction(this, n"ActivationPointActivated");
		RotatePlatformTimeline.BindUpdate(this, n"RotatePlatformTimelineUpdate");
		LerpHingeLightsTimeline.BindUpdate(this, n"LerpHingeLightsTimelineUpdate");
		MeshRoot.SetRelativeRotation(StartingRot);
		HingeMeshBase.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", HingeUnlitColor);

		for (auto Light : ConnectedPointLights)
		{
			Light.LightComponent.SetIntensity(0.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshRoot.SetRelativeRotation(bShowTargetState ? TargetRot : StartingRot);
	}

	UFUNCTION()
	void ActivationPointActivated(bool bActivated)
	{
		bActivated ? RotatePlatformTimeline.Play() : RotatePlatformTimeline.Reverse();
		bActivated ? LerpHingeLightsTimeline.Play() : LerpHingeLightsTimeline.Reverse();

		if(bActivated && !bTrussIsUp)
			UHazeAkComponent::HazePostEventFireForget(TrussMoveUpAudioEvent, this.GetActorTransform());
		else if(!bActivated && bTrussIsUp)
			UHazeAkComponent::HazePostEventFireForget(TrussMoveDownAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void RotatePlatformTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRot, TargetRot, CurrentValue));

		if(bTrussIsUp && CurrentValue == 0.0f)
		{
			UHazeAkComponent::HazePostEventFireForget(TrussIsDownAudioEvent, this.GetActorTransform());
			bTrussIsUp = false;
		}
		if(!bTrussIsUp && CurrentValue == 1.0f)
		{
			UHazeAkComponent::HazePostEventFireForget(TrussIsUpAudioEvent, this.GetActorTransform());
			bTrussIsUp = true;
		}
	}

	UFUNCTION()
	void LerpHingeLightsTimelineUpdate(float CurrentValue)
	{
		HingeMeshBase.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FMath::Lerp(HingeUnlitColor, HingeLitColor, CurrentValue));

		for (auto Light : ConnectedPointLights)
		{
			Light.LightComponent.SetIntensity(FMath::Lerp(0.f, 20.f, CurrentValue));
		}
	}
}