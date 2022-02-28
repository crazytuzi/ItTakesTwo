import Vino.Interactions.InteractionComponent;

class ALiftBlockActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent StaticMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractionComponent InteractionPoint;

	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 250.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Box;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractionComponent InteractionPointOtherSide;

	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 250.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Box;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);


		
	UPROPERTY(Meta = (MakeEditWidget))
	FVector FullyOpenLocation;
	
	UPROPERTY(Meta = (MakeEditWidget))
	FVector InteractionLocation;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector OtherSideInteractionLocation;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	UPROPERTY()
	float LiftMultiplier = 1.3f;
		
	float Resistance = 5.f;
	float PositionAlpha = 0.f;
	float FirstInteractionButtonMashRate = 0.f;
	float SecondInteractionButtonMashRate = 0.f;

	float NetworkSendTimer = 0.2f;
	float NetworkMashRate = 0.f;
	
	
	FVector NewLocation;
	FVector StartLocation;

	AHazePlayerCharacter InteractingPlayer;

	AHazePlayerCharacter OtherSideInteractingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = StaticMesh.GetRelativeLocation();
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		InteractionPoint.SetRelativeLocation(InteractionLocation);

		InteractionPointOtherSide.OnActivated.AddUFunction(this, n"OnOtherSideInteractionActivated");
		InteractionPointOtherSide.SetRelativeLocation(OtherSideInteractionLocation);

		Capability::AddPlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CombinedMashRate = FirstInteractionButtonMashRate + SecondInteractionButtonMashRate + NetworkMashRate;
		PositionAlpha += CombinedMashRate * (LiftMultiplier * DeltaTime);
		PositionAlpha -= Resistance * DeltaTime;
		PositionAlpha = FMath::Clamp(PositionAlpha, 0.f, 1.f);
		NewLocation = FMath::Lerp(StartLocation, FullyOpenLocation, PositionAlpha);
		FVector FinalLoc = FMath::VInterpTo(StaticMesh.GetRelativeLocation(), NewLocation, DeltaTime, 15.f);
		
		StaticMesh.SetRelativeLocation(FinalLoc);

		if (InteractingPlayer == nullptr)
			FirstInteractionButtonMashRate = 0.f;
	
		if (OtherSideInteractingPlayer == nullptr)
			SecondInteractionButtonMashRate = 0.f;
		
		if (NetworkSendTimer <= 0.f)
		{
			NetSetMashRates(FirstInteractionButtonMashRate + SecondInteractionButtonMashRate, HasControl());
			NetworkSendTimer = 0.2f;
		}
		NetworkSendTimer -= DeltaTime;
	}

	UFUNCTION(BlueprintCallable)
	void TestLift(float PositionAlphaValue)
	{
		PositionAlpha = PositionAlphaValue;
	}

	UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionPoint.Disable(n"PlayerInput");
		Player.SetCapabilityAttributeObject(n"LiftBlockActor", this);
		Player.SetCapabilityAttributeObject(n"ButtonMashPosition", InteractionPoint);
		InteractingPlayer = Player;
    }

	UFUNCTION()
	void InteractingPlayerCancel()
	{
		InteractingPlayer.SetCapabilityAttributeObject(n"LiftBlockActor", nullptr);
		InteractingPlayer = nullptr;
		InteractionPoint.Enable(n"PlayerInput");
	}
	
	UFUNCTION()
	void OnOtherSideInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		InteractionPointOtherSide.Disable(n"PlayerInput");
		Player.SetCapabilityAttributeObject(n"LiftBlockActor", this);
		Player.SetCapabilityAttributeObject(n"ButtonMashPosition", InteractionPointOtherSide);
		OtherSideInteractingPlayer = Player;
	}

	UFUNCTION()
	void OtherSideInteractingPlayerCancel()
	{
		OtherSideInteractingPlayer.SetCapabilityAttributeObject(n"LiftBlockActor", nullptr);
		OtherSideInteractingPlayer = nullptr;
		InteractionPointOtherSide.Enable(n"PlayerInput");
	}

	UFUNCTION(NetFunction)
	void NetSetMashRates(float NetMashrate, bool bControlSide)
	{
		if (HasControl() == bControlSide)
		{
			return;
		}
		NetworkMashRate = NetMashrate;
	}


}