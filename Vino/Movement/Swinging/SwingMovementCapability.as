

// import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
// import Vino.Movement.Swinging.SwingComponent;

// class USwingMovementCapability : UCharacterMovementCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(CapabilityTags::MovementAction);
// 	default CapabilityTags.Add(n"Swinging");
// 	default CapabilityTags.Add(n"SwingingMovement");

// 	default CapabilityDebugCategory = n"Movement Swinging";

// 	default TickGroup = ECapabilityTickGroups::ActionMovement;
// 	default TickGroupOrder = 5;

// 		UPROPERTY(Category = "Attribute")
// 	float SwingDuration = 2.3f;
// 	UPROPERTY(NotEditable, Category = "Attribute")
// 	float SwingDurationCurrent = 0.f;
// 	FVector SwingAxis;
// 	float SwingRotationSpeed = 80.f;
// 	float SwingDirection = 1.f;
// 	float SwingAngleMax = 160.f;

// 	AHazePlayerCharacter OwningPlayer;
// 	USwingingComponent SwingingComponent;
// 	USwingPointComponent ActiveSwingPoint;

// 	UPROPERTY()
// 	UCurveFloat SwingCurve;


// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Super::Setup(SetupParams);

// 		if (FMath::RandBool())
// 			SwingDirection = -1.f;	

// 		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
// 		SwingingComponent = USwingingComponent::GetOrCreate(Owner);
// 	}

// 	UFUNCTION(BlueprintPure)
// 	float GetSwingDurationPercentage()
// 	{
// 		return FMath::Clamp(SwingDurationCurrent / SwingDuration, 0.f, 1.f);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (SwingingComponent.GetActiveSwingPoint() == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkActivation::DontActivate;
        
// 		return EHazeNetworkActivation::ActivateLocal;
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{		
// 		if (ActiveSwingPoint != SwingingComponent.GetActiveSwingPoint())
// 			return EHazeNetworkDeactivation::DeactivateLocal;
			
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		ActiveSwingPoint = SwingingComponent.GetActiveSwingPoint();

// 		FVector ClosestPointOnSwingSphere = ActiveSwingPoint.GetClosestPointOnSwingSphere(OwningPlayer.CapsuleComponent.WorldLocation);
// 		System::DrawDebugLine(ActiveSwingPoint.WorldLocation, ClosestPointOnSwingSphere);

// 		FVector SwingPointToSwingSphere = ClosestPointOnSwingSphere - ActiveSwingPoint.WorldLocation;		
// 		SwingAxis = FVector::UpVector.CrossProduct(SwingPointToSwingSphere).GetSafeNormal();

// 		SwingDurationCurrent = 0.f;

// 		OwningPlayer.BlockCapabilities(n"Movement", this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		OwningPlayer.Mesh.SetRelativeLocation(FVector::ZeroVector);
// 		OwningPlayer.Mesh.SetRelativeRotation(FRotator::ZeroRotator);

// 		OwningPlayer.UnblockCapabilities(n"Movement", this);
// 		ActiveSwingPoint = nullptr;	
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{		
// 		SwingDurationCurrent += DeltaTime;
// 		if (SwingDurationCurrent >= SwingDuration)
// 			SwingDurationCurrent -= SwingDuration;

// 		float SwingTime	= SwingDurationCurrent;
// 		SwingTime = SwingCurve.GetFloatValue(SwingTime / SwingDuration);

// 		MovePlayer(SwingTime, DeltaTime);
// 		RotateMesh();
// 	}	



// 	void MovePlayer(float SwingTime, float DeltaTime)
// 	{
// 		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swinging");
// 		FrameMove.OverrideStepDownHeight(0.f);


// 		float RotationScale = GetAttributeVector(AttributeVectorNames::MovementRaw).Y;
// 		SwingAxis = SwingAxis.RotateAngleAxis(RotationScale * SwingRotationSpeed * DeltaTime, FVector::UpVector);
// 		//ActiveSwingPoint.SwingAxis = ActiveSwingPoint.SwingAxis.RotateAngleAxis(RotationScale * SwingRotationSpeed * SwingDirection * DeltaTime, FVector::UpVector);		

// 		FVector SwingVector = FVector::UpVector * ActiveSwingPoint.SwingRangeDistance * -1;
// 		SwingVector = SwingVector.RotateAngleAxis(SwingAngleMax * SwingTime * 0.5f, SwingAxis);

// 		System::DrawDebugLine(ActiveSwingPoint.WorldLocation, ActiveSwingPoint.WorldLocation + (SwingAxis * 500), LineColor = FLinearColor::Green);
// 		System::DrawDebugLine(ActiveSwingPoint.WorldLocation, ActiveSwingPoint.WorldLocation + SwingVector, LineColor = FLinearColor::Red);

// 		FVector TargetLocation = ActiveSwingPoint.WorldLocation + SwingVector;
// 		FVector DeltaMove = TargetLocation - SwingingComponent.PlayerLocation;
// 		FrameMove.ApplyDelta(DeltaMove);

// 		// Rotate the capsule in the direction of the swing
// 		FVector PlayerToSwingPoint = ActiveSwingPoint.WorldLocation - OwningPlayer.ActorLocation;
// 		FVector SwingForward = PlayerToSwingPoint.CrossProduct(SwingAxis);
// 		FrameMove.SetRotation(Math::MakeRotFromX(SwingForward).Quaternion());

// 		MoveCharacter(FrameMove, n"Swinging");		
// 	}

// 	void RotateMesh()
// 	{
// 		FVector PlayerToSwingPoint = ActiveSwingPoint.WorldLocation - OwningPlayer.ActorLocation;
// 		FVector SwingForward = PlayerToSwingPoint.CrossProduct(SwingAxis);
// 		OwningPlayer.Mesh.SetWorldRotation(Math::MakeRotFromX(SwingForward));

// 		FVector RelativeLocation = OwningPlayer.ActorLocation - OwningPlayer.CapsuleComponent.WorldLocation;

// 		FRotator NewRotation = Math::MakeRotFromX(SwingForward);
// 		FVector RotatedRelative = NewRotation.RotateVector(RelativeLocation);

// 		OwningPlayer.Mesh.SetRelativeLocation(OwningPlayer.ActorTransform.InverseTransformVector(RotatedRelative) - RelativeLocation);
// 	}
// }