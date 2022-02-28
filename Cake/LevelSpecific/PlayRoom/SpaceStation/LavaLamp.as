class ALavaLamp : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent LavaLamp;

    UPROPERTY(DefaultComponent, Attach = LavaLamp)
    USphereComponent InfluenceRadius;
    default InfluenceRadius.SphereRadius = 750.f;
    default InfluenceRadius.RelativeLocation = FVector(0.f, 0.f, 300.f);

    UPROPERTY(DefaultComponent, Attach = LavaLamp)
	UHazeTriggerComponent InteractionPoint;

	UPROPERTY()
	FVector CurrentGravityDirection = -FVector::UpVector;

    FRotator TargetUpRotation = FVector::UpVector.Rotation();
    FHazeAcceleratedRotator UpRotation;
    default UpRotation.Value = TargetUpRotation;
    default UpRotation.Velocity = FRotator::ZeroRotator;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetupTriggerComponent();
    }

    void SetupTriggerComponent()
	{
        FHazeShapeSettings ActionShape;
		ActionShape.SphereRadius = 250.f;
		ActionShape.Type = EHazeShapeType::Sphere;

		FTransform ActionTransform;
		ActionTransform.SetScale3D(FVector(1.f));

		FHazeDestinationSettings MovementSettings;
		//MovementSettings.MovementMethod = EHazeMovementMethod::Disabled;

		FHazeActivationSettings ActivationSettings;
		ActivationSettings.ActivationType = EHazeActivationType::Action;

		FHazeTriggerVisualSettings VisualSettings;
		VisualSettings.VisualOffset.Location = FVector(0.f, 0.f, 125.f);

		InteractionPoint.AddActionShape(ActionShape, ActionTransform);
		InteractionPoint.AddMovementSettings(MovementSettings);
		InteractionPoint.AddActivationSettings(ActivationSettings);
		InteractionPoint.SetVisualSettings(VisualSettings);

		FHazeTriggerActivationDelegate InteractionDelegate;
		InteractionDelegate.BindUFunction(this, n"OnInteractedWith");
		InteractionPoint.AddActivationDelegate(InteractionDelegate);
	}

    UFUNCTION(NotBlueprintCallable)
	void OnInteractedWith(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
	{
		/*CurrentGravityDirection = -CurrentGravityDirection;
        TArray<AActor> NearbyActors;
        InfluenceRadius.GetOverlappingActors(NearbyActors, nullptr);

        for(AActor Actor : NearbyActors)
        {			
			UModifiableGravityComponent GravityComponent = Cast<UModifiableGravityComponent>(Actor.GetComponentByClass(UModifiableGravityComponent::StaticClass()));
			if(GravityComponent != nullptr)
			{
				GravityComponent.FlipGravity();
			}

			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);

			if(Player != nullptr)
			{
				FlipPlayer(Player);
				Player.SetCapabilityActionState(n"InvertingGravity", EHazeActionState::Active);
			}
        }*/
	}

	UFUNCTION(BlueprintEvent)
	void FlipPlayer(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION()
	void UpdateCameraYawAxis(AHazePlayerCharacter Player, FVector WorldUp)
	{
		UHazeActiveCameraUserComponent CamUserComp = UHazeActiveCameraUserComponent::Get(Player);

		CamUserComp.SetYawAxis(WorldUp);
	}
}