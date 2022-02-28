import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Climbing.3DClimbing.PlayerClimbingComponent;
import Vino.Camera.Capabilities.CameraTags;

class UPlayerClimbingSwingCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 104;

	AHazePlayerCharacter Player;
	UPlayerClimbingComponent ClimbingComponent;
	FVector LastPivotLocation;

	FVector Velocity;	

	float Drag = 1.0f;

	float Gravity = 3500.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		ClimbingComponent = UPlayerClimbingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ClimbingComponent.LastMagneticComponent != nullptr && ClimbingComponent.ActiveMagneticComponent == ClimbingComponent.LastMagneticComponent )
			return EHazeNetworkActivation::DontActivate;

		if(ClimbingComponent.GetMagneticComponent() == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(ClimbingComponent.PlayerMagneticComponent.bIsPositive == ClimbingComponent.ActiveMagneticComponent.bIsPositive)
			return EHazeNetworkActivation::DontActivate;			

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(!ClimbingComponent.bIsSwinging)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ClimbingComponent.ActiveMagneticComponent.bIsActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		// if(WasActionStarted(ActionNames::TEMPRightFaceButton))
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(WasActionStarted(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ClimbingComponent.LastMagneticComponent = ClimbingComponent.ActiveMagneticComponent;
		//ClimbingComponent.PlayerMagneticComponent.bIsAnchored = true;
		//AttachRadius = (Player.GetActorLocation() - ClimbingComponent.ActiveMagneticComponent.GetWorldLocation()).Size();
		ClimbingComponent.bIsSwinging = true;
		//ClimbingComponent.bCanJump = true;
		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);

		LastPivotLocation = ClimbingComponent.ActiveMagneticComponent.GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClimbingComponent.bIsSwinging = false;
		ClimbingComponent.bCanJump = false;
		ClimbingComponent.PlayerMagneticComponent.bIsAnchored = false;
		Player.Mesh.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);

		Player.AddImpulse(Velocity * 1.2f);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(ClimbingComponent.LastMagneticComponent != nullptr)
			if(!ClimbingComponent.bIsSwinging)
				if((Player.GetActorCenterLocation() - ClimbingComponent.LastMagneticComponent.GetWorldLocation()).Size() > ClimbingComponent.PlayerMagneticComponent.Radius)
					{
						ClimbingComponent.LastMagneticComponent = nullptr;
						Print("Cleared LastMagneticComponent!", 2.f);
					}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector SwingPivotLocation = ClimbingComponent.ActiveMagneticComponent.GetWorldLocation();

		FVector SwingPivotDelta = SwingPivotLocation - LastPivotLocation;

		FVector TargetLocation = Player.GetActorLocation();

		FVector DeltaVelocity;

		FVector MovementVelocity;

		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		FVector Direction = SwingPivotLocation - TargetLocation;
		Direction.Normalize();

		FVector ClosestSphereLocation = SwingPivotLocation - Direction * ClimbingComponent.ActiveMagneticComponent.AttractionRadius;
	
		float CurrentDistance = (TargetLocation - ClosestSphereLocation).Size();

		FVector Right = Input.CrossProduct(Direction);
		if(Direction.Z < 0)
			Right = -Right;
		Input = Direction.CrossProduct(Right);

		Velocity += Input * 2800.0f* DeltaTime;

		FVector AttractionForce = ClosestSphereLocation - TargetLocation;
		AttractionForce = AttractionForce / 40.0f;

		if(AttractionForce.Size() > 4.0f)
		{
			AttractionForce = AttractionForce.GetSafeNormal() * 4.0f;
		}


		Velocity += AttractionForce * 5000.0f * DeltaTime;

		FVector GravityDirection = -FVector::UpVector;
		FVector GravityRight = GravityDirection.CrossProduct(Direction);
		GravityDirection = Direction.CrossProduct(GravityRight);


		ClimbingComponent.bCanJump = true;

		DeltaVelocity += SwingPivotDelta * 0.4f;

		Velocity += FVector::UpVector * -Gravity * DeltaTime;
		Velocity -= Velocity * Drag * DeltaTime;

		LastPivotLocation = SwingPivotLocation;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwingMovement");

		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);
		FrameMove.ApplyDelta(DeltaVelocity);
		FrameMove.ApplyVelocity(Velocity);
		FrameMove.ApplyGravityAcceleration();

		FRotator Rotation = Math::MakeRotFromXZ(MoveComp.GetVelocity(), SwingPivotLocation - Player.GetActorLocation());
		FRotator InterpRotation = FMath::RInterpTo(Player.GetActorRotation(), Rotation, DeltaTime, 3.f);
		FrameMove.SetRotation(InterpRotation.Quaternion());

		MoveCharacter(FrameMove, n"ClimbingSwing");
	}
}