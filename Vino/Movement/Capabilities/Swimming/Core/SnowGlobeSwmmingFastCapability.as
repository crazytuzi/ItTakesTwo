// import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
// import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
// import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
// import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
// import Vino.Movement.Capabilities.Swimming.Core.SnowGlobeSwimmingStatics;
// import Vino.Movement.Jump.AirJumpsComponent;

// class USnowGlobeSwimmingFastCapability : UCharacterMovementCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(MovementSystemTags::Swimming);
// 	default CapabilityTags.Add(SwimmingTags::Underwater);
// 	default CapabilityTags.Add(SwimmingTags::Fast);

// 	default CapabilityDebugCategory = n"Movement Swimming";
	
// 	default TickGroup = ECapabilityTickGroups::LastMovement;
// 	default TickGroupOrder = 99;

// 	AHazePlayerCharacter Player;
// 	USnowGlobeSwimmingComponent SwimComp;
// 	UCharacterAirJumpsComponent AirJumpsComp;

// 	float NoInputDuration = 0.f;
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
// 	void PreTick(float DeltaTime)
// 	{
// 		if (IsActive() && GetAttributeVector(AttributeVectorNames::MovementDirection).IsNearlyZero())
// 			NoInputDuration += DeltaTime;
// 		else
// 			NoInputDuration = 0.f;		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (!SwimComp.bIsInWater)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!SwimComp.bIsBoosting)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (IsActioning(n"ForceJump"))
// 			return EHazeNetworkActivation::DontActivate;

// 		if (GetAttributeVector(AttributeVectorNames::MovementDirection).Size() >= 0.1f || IsActioning(ActionNames::MovementJump) || IsActioning(ActionNames::Cancel))
// 			return EHazeNetworkActivation::ActivateUsingCrumb;

// 		return EHazeNetworkActivation::DontActivate;		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (!MoveComp.CanCalculateMovement())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if (SwimComp.SwimmingState != ESwimmingState::Fast)
// 			return EHazeNetworkDeactivation::DeactivateLocal;		

// 		if (!SwimComp.bIsInWater)
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if (NoInputDuration < 0.1f || IsActioning(ActionNames::MovementJump) || IsActioning(ActionNames::Cancel))
// 			return EHazeNetworkDeactivation::DontDeactivate;

// 		return EHazeNetworkDeactivation::DeactivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		SwimComp.SwimmingState = ESwimmingState::Fast;
// 		ControlRotation.SnapTo(Player.ControlRotation);

// 		Owner.BlockCapabilities(n"AirJump", this);
// 		Owner.BlockCapabilities(n"AirDash", this);
// 		AirJumpsComp.ResetJumpAndDash();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		SwimComp.bIsBoosting = false;

// 		Owner.UnblockCapabilities(n"AirJump", this);
// 		Owner.UnblockCapabilities(n"AirDash", this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		SwimmingStatics::UpdateControlRotation(Player, DeltaTime, GetAttributeVector2D(AttributeVectorNames::CameraDirection), ControlRotation);

// 		if (MoveComp.CanCalculateMovement())
// 		{
// 			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingFast");
// 			CalculateFrameMove(FrameMove, DeltaTime);
// 			MoveCharacter(FrameMove, n"SwimmingFast");
			
// 			CrumbComp.LeaveMovementCrumb();	
// 		}
// 	}

// 	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
// 	{	
// 		if (HasControl())
// 		{
// 			FVector Velocity = MoveComp.GetVelocity(); 

// 			FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);
// 			//Print("Input: " + Input);
// 			Input.Z = 0.f; 
			
// 			FVector CameraRelativeInput = ControlRotation.Value.RotateVector(Input);

// 			FVector StickAcceleration = CameraRelativeInput * SwimmingSettings.FastAcceleration;

// 			float UpwardsScale = 0.f;
// 			if (IsActioning(ActionNames::MovementJump))
// 				UpwardsScale += SwimmingSettings.FastVerticalScale;
// 			if (IsActioning(ActionNames::Cancel))
// 				UpwardsScale -= SwimmingSettings.FastVerticalScale;
// 			FVector ButtonAcceleration = MoveComp.WorldUp * UpwardsScale * SwimmingSettings.FastAcceleration;
			
// 			FVector Acceleration = (StickAcceleration + ButtonAcceleration).GetClampedToMaxSize(SwimmingSettings.FastAcceleration);

// 			Velocity -= Velocity * SwimmingSettings.FastDrag * DeltaTime; 
// 			Velocity += Acceleration * DeltaTime;

// 			//Velocity = Velocity.GetClampedToMaxSize(SwimmingSettings.TargetFastSpeed);

// 			FrameMove.OverrideCollisionSolver(USwimmingCollisionSolver::StaticClass());
// 			FrameMove.ApplyVelocity(Velocity);
// 			FrameMove.ApplyAndConsumeImpulses();
// 			FrameMove.OverrideStepUpHeight(0.f);
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
