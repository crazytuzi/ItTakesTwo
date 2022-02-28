// import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
// import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
// import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
// import Vino.Movement.Capabilities.Swimming.SwimmingSettings;
// import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
// import Vino.Movement.Capabilities.Swimming.Core.SnowGlobeSwimmingStatics;
// import Vino.Movement.Jump.AirJumpsComponent;

// class USnowGlobeSwimmingSlowCapability : UCharacterMovementCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(MovementSystemTags::Swimming);
// 	default CapabilityTags.Add(SwimmingTags::Underwater);
// 	default CapabilityTags.Add(SwimmingTags::Slow);

// 	default CapabilityDebugCategory = n"Movement Swimming";
	
// 	default TickGroup = ECapabilityTickGroups::LastMovement;
// 	default TickGroupOrder = 100;

// 	AHazePlayerCharacter Player;
// 	USnowGlobeSwimmingComponent SwimComp;
// 	UCharacterAirJumpsComponent AirJumpsComp;
// 	FHazeAcceleratedRotator ControlRotation;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Super::Setup(SetupParams);
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
// 		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Player);
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (!SwimComp.bIsInWater)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkActivation::DontActivate;

// 		if (IsActioning(n"ForceJump"))
// 			return EHazeNetworkActivation::DontActivate;	

//         return EHazeNetworkActivation::ActivateUsingCrumb;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if (SwimComp.SwimmingState != ESwimmingState::Slow)
// 			return EHazeNetworkDeactivation::DeactivateLocal;		

// 		if (!SwimComp.bIsInWater)
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		SwimComp.SwimmingState = ESwimmingState::Slow;
// 		ControlRotation.SnapTo(Player.ControlRotation);

// 		Owner.BlockCapabilities(n"AirJump", this);
// 		Owner.BlockCapabilities(n"AirDash", this);
// 		AirJumpsComp.ResetJumpAndDash();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Owner.UnblockCapabilities(n"AirJump", this);
// 		Owner.UnblockCapabilities(n"AirDash", this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		SwimmingStatics::UpdateControlRotation(Player, DeltaTime, GetAttributeVector2D(AttributeVectorNames::CameraDirection), ControlRotation);

// 		if (MoveComp.CanCalculateMovement())
// 		{
// 			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingSlow");
// 			CalculateFrameMove(FrameMove, DeltaTime);
// 			MoveCharacter(FrameMove, n"Swimming");
			
// 			CrumbComp.LeaveMovementCrumb();	
// 		}
// 	}	

// 	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
// 	{	
// 		if (HasControl())
// 		{
// 			FVector Velocity = MoveComp.GetVelocity(); 

// 			FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);
// 			Input.Z = 0.f; 

// 			FVector CameraRelativeInput = ControlRotation.Value.RotateVector(Input);
// 			FVector Acceleration = CameraRelativeInput * SwimmingSettings.SlowAcceleration;

// 			float UpwardsScale = 0.f;
// 			if (IsActioning(ActionNames::MovementJump))
// 				UpwardsScale += SwimmingSettings.SlowVerticalScale;
// 			if (IsActioning(ActionNames::Cancel))
// 				UpwardsScale -= SwimmingSettings.SlowVerticalScale;
			
// 			Acceleration += MoveComp.WorldUp * UpwardsScale * SwimmingSettings.SlowAcceleration;
// 			Acceleration = Acceleration.GetClampedToMaxSize(SwimmingSettings.SlowAcceleration);

// 			Velocity -= Velocity * SwimmingSettings.SlowDrag * DeltaTime; 
// 			Velocity += Acceleration * DeltaTime;

// 			Velocity = Velocity.GetClampedToMaxSize(SwimmingSettings.TargetSlowSpeed);

// 			FrameMove.OverrideCollisionSolver(USwimmingCollisionSolver::StaticClass());
// 			FrameMove.ApplyVelocity(Velocity);
// 			FrameMove.ApplyAndConsumeImpulses();
// 			FrameMove.OverrideStepDownHeight(0.f);
// 			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);

// 			if (Velocity.Size() >= 0.1f)
// 			{ 
// 				MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal(), 6.f);
// 				FrameMove.ApplyTargetRotationDelta();
// 			}

// 			if (UpwardsScale != 0.f)
// 				NetUpdateSwimmingForwards(1.f);			
// 			else
// 				NetUpdateSwimmingForwards(Input.Size());		
// 		}
// 		else
// 		{
// 			FHazeActorReplicationFinalized ConsumedParams;
// 			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
// 			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
// 		}	
// 	}

// 	UFUNCTION(NetFunction)
// 	void NetUpdateSwimmingForwards(float InputSize)
// 	{
// 		SwimComp.bIsSwimmingForward = InputSize >= 0.1f;
// 	}
// }
