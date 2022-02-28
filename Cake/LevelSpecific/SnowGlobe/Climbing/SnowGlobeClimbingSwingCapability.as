import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingComponent;
class USnowGlobeClimbingSwingCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 104;

	AHazePlayerCharacter Player;
	USnowGlobeClimbingComponent ClimbingComponent;
	float AttachRadius;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		ClimbingComponent = USnowGlobeClimbingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(ActionNames::PrimaryLevelAbility))
			if(!ClimbingComponent.bHasGrip)
				//if(ClimbingComponent.bCanJump)
					if(ClimbingComponent.LastMagneticComponent == nullptr || ClimbingComponent.ActiveMagneticComponent != ClimbingComponent.LastMagneticComponent)
						if(ClimbingComponent.GetMagneticComponent() != nullptr && ClimbingComponent.ActiveMagneticComponent.bIsAnchored)
							return EHazeNetworkActivation::ActivateLocal;

		if(WasActionStarted(ActionNames::PrimaryLevelAbility))
			if(!ClimbingComponent.bHasGrip)
				if(ClimbingComponent.GetMagneticComponent() != nullptr && ClimbingComponent.ActiveMagneticComponent.bIsAnchored)
					return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(ClimbingComponent.bHasGrip)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ClimbingComponent.bIsSwinging)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ClimbingComponent.ActiveMagneticComponent.bIsActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if(WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ClimbingComponent.LastMagneticComponent = ClimbingComponent.ActiveMagneticComponent;
		//ClimbingComponent.PlayerMagneticComponent.bIsAnchored = true;
		AttachRadius = ClimbingComponent.ActiveMagneticComponent.Radius;
		//AttachRadius = (Player.GetActorLocation() - ClimbingComponent.ActiveMagneticComponent.GetWorldLocation()).Size();
		ClimbingComponent.bIsSwinging = true;
		//ClimbingComponent.bCanJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ClimbingComponent.bIsSwinging = false;
		ClimbingComponent.bCanJump = false;
		ClimbingComponent.PlayerMagneticComponent.bIsAnchored = false;
		Player.Mesh.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
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
		// Adjust Swing Pivot to Spline Lock
		UHazeSplineComponentBase Spline = Cast<UHazeSplineComponentBase>(GetAttributeObject(n"SplineLockRef"));
		FVector SplineRightVector;

		if(Spline != nullptr)
			SplineRightVector = Spline.FindRightVectorClosestToWorldLocation(Player.GetActorLocation(), ESplineCoordinateSpace::World);

		FVector SwingPivotLocation = ClimbingComponent.ActiveMagneticComponent.GetWorldLocation();

		if(Spline != nullptr)
			SwingPivotLocation = SwingPivotLocation.PointPlaneProject(Player.GetActorLocation(), SplineRightVector);

		if(ClimbingComponent.PlayerMagneticComponent.bIsPositive != ClimbingComponent.ActiveMagneticComponent.bIsPositive)
		{
			FVector TargetLocation = Player.GetActorLocation() + (MoveComp.Velocity * DeltaTime);
			
			if(Spline != nullptr)
				TargetLocation = TargetLocation.PointPlaneProject(Player.GetActorLocation(), SplineRightVector);

			float CurrentDistance = (TargetLocation - SwingPivotLocation).Size();
			
			if(CurrentDistance > AttachRadius /*&& (Player.GetActorCenterLocation().Z < SwingPivotLocation.Z)*/)
			{
				FVector AttachDirection = (TargetLocation - SwingPivotLocation).GetSafeNormal();
				FVector ConstrainedLocation = SwingPivotLocation + (AttachDirection * AttachRadius);

				if(Spline != nullptr)
					ConstrainedLocation = ConstrainedLocation.PointPlaneProject(Player.GetActorLocation(), SplineRightVector);				

				FVector InterpLocation = FMath::VInterpTo(TargetLocation, ConstrainedLocation, DeltaTime, 2.5f);		
				FVector DeltaVelocity = InterpLocation - Player.GetActorLocation();
				FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
				FVector MovementVelocity = Input * 1500.f * DeltaTime;
				FVector Drag = -DeltaVelocity * 0.f;

				FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwingMovement");

				FrameMove.OverrideStepUpHeight(0.f);
				FrameMove.OverrideStepDownHeight(0.f);
				FrameMove.ApplyDelta(DeltaVelocity);
				FrameMove.ApplyVelocity(MovementVelocity);
				FrameMove.ApplyVelocity(Drag);
				//FrameMove.ApplyVelocity((ClimbingComponent.ActiveMagneticComponent.GetWorldLocation() - Player.GetActorLocation()).GetSafeNormal() * 5000.f * DeltaTime);
				FrameMove.ApplyGravityAcceleration();

				FRotator Rotation = Math::MakeRotFromXZ(MoveComp.GetVelocity(), SwingPivotLocation - Player.GetActorLocation());
				FRotator InterpRotation = FMath::RInterpTo(Player.GetActorRotation(), Rotation, DeltaTime, 3.f);
				FrameMove.SetRotation(InterpRotation.Quaternion());

				MoveCharacter(FrameMove, n"ClimbingSwing");

				ClimbingComponent.bCanJump = true;
			}			
		}

		/*
		FRotator Rotation = Math::MakeRotFromXZ(MoveComp.GetVelocity(), ClimbingComponent.ActiveMagneticComponent.GetWorldLocation() - Player.GetActorLocation());
		//FRotator Rotation = Math::MakeRotFromZ(ClimbingComponent.ActiveMagneticComponent.GetWorldLocation() - Player.GetActorLocation());
		FRotator InterpRotation = FMath::RInterpTo(Player.GetActorRotation(), Rotation, DeltaTime, 10.f);
		Player.Mesh.SetWorldRotation(Rotation);
		*/

	}
}