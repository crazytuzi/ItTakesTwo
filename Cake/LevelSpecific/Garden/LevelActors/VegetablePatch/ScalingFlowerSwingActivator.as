import Vino.Movement.Swinging.SwingPoint;

class AScalingFlowerSwingActivator : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASwingPoint SwingPointToActivate;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartScalingAudioEvent;

	UPROPERTY(Category = "Settings")
	FHazeTimeLike ScaleTimelike;

	UPROPERTY(Category = "Settings")
	FVector StartingScale = FVector::OneVector;
	FVector DefaultScale = FVector::OneVector;

	UPROPERTY(Category = "Settings")
	int DynamicMaterialIndex = 0;
	UMaterialInstanceDynamic DynMat;

	UPROPERTY(Category = "Settings")
	bool bShouldScaleActor = false;

	UPROPERTY(Category = "Settings")
	bool bShouldUnWitherActor = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.RelativeScale3D = StartingScale;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScaleTimelike.BindUpdate(this, n"OnScaleUpdate");
		ScaleTimelike.BindFinished(this ,n"OnScaleFinished");

		if(bShouldUnWitherActor)
			DynMat = Mesh.CreateDynamicMaterialInstance(DynamicMaterialIndex);

		DefaultScale = Mesh.RelativeScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void StartScaling()
	{
		ScaleTimelike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(StartScalingAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void OnScaleUpdate(float Value)
	{
		if(bShouldScaleActor)
		{
			FVector ScaleToSet = FMath::VLerp(DefaultScale, FVector::OneVector, FVector(Value,Value,Value));
			Mesh.SetRelativeScale3D(ScaleToSet);
		}

		if(bShouldUnWitherActor && DynMat != nullptr)
			DynMat.SetScalarParameterValue(n"BlendValue", Value);
	}

	UFUNCTION()
	void OnScaleFinished()
	{
		if(SwingPointToActivate != nullptr)
			SwingPointToActivate.SwingPointComponent.SetSwingPointEnabled(true);
	}

	UFUNCTION()
	void SetFinished()
	{
		Mesh.SetRelativeScale3D(1.f);
		
		if(SwingPointToActivate != nullptr)
			SwingPointToActivate.SwingPointComponent.SetSwingPointEnabled(true);
		
		if(bShouldUnWitherActor && DynMat != nullptr)
			DynMat.SetScalarParameterValue(n"BlendValue", 1.f);
	}
}