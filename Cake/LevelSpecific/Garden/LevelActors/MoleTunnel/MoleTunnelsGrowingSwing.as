import Cake.LevelSpecific.Garden.LevelActors.WateringPlantActor;
event void FOnBlendFinished();
class AMoleTunnelsGrowingSwing: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase MeshBody;

	UPROPERTY()
	AWateringPlantActor WateringPlantActor;
	UPROPERTY()
	AStaticMeshActor PlantBlendActor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GrowAwayAudioEvent;

	UPROPERTY()
    FOnBlendFinished OnBlendFinished;

	UPROPERTY()
	UAnimSequence MHDown;
	UPROPERTY()
	UAnimSequence GrowingAway;
	UPROPERTY()
	UAnimSequence MHUp;

	UMaterialInstanceDynamic Material;

	FHazeAcceleratedFloat AcceleratedFloat;
	bool bStartBlend;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if(WateringPlantActor != nullptr)
		{
			WateringPlantActor.AttachToComponent(MeshBody, n"PlantSocket", EAttachmentRule::SnapToTarget);
			FHitResult Hit;
			WateringPlantActor.SetActorRelativeRotation(FRotator(90.f, 0.f, 0.f),false, Hit, false);
		}
		Material = PlantBlendActor.StaticMeshComponent.CreateDynamicMaterialInstance(0);
		AcceleratedFloat.Value = 1;
		Material.SetScalarParameterValue(n"BlendValue", AcceleratedFloat.Value);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bStartBlend)
		{
			if(AcceleratedFloat.Value >= 0.05)
				AcceleratedFloat.SpringTo(0, 0.4, 0.65, DeltaTime);
			if(AcceleratedFloat.Value < 0.05)
				AcceleratedFloat.SpringTo(0, 0.1, 0.65, DeltaTime * 0.5f);

			Material.SetScalarParameterValue(n"BlendValue", AcceleratedFloat.Value);

			if(AcceleratedFloat.Value <= 0)
			{
				bStartBlend = false;
				if(Game::GetMay().HasControl())
				{
					NetBlendFinished();
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetBlendFinished()
	{
		OnBlendFinished.Broadcast();
	}


	UFUNCTION()
	void GrowAway()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"GrowAwayFinished");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = GrowingAway, bLoop = false);
		UHazeAkComponent::HazePostEventFireForget(GrowAwayAudioEvent, this.GetActorTransform());
	}


	UFUNCTION()
	void GrowAwayFinished()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = MHUp, bLoop = true);
	}

	UFUNCTION()
	void StartBlend()
	{
		bStartBlend = true;
	}

}

