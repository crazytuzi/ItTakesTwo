import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingComponent;
class USnowGlobeClimbingJumpCapability : UCharacterMovementCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	USnowGlobeClimbingComponent ClimbingComponent;
	AHazePlayerCharacter Player;

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
		if(ClimbingComponent.bCanJump)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!ClimbingComponent.bHasGrip)
			if(!ClimbingComponent.bIsSwinging)
				return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Jump", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Jump", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Adjust Swing Pivot to Spline Lock
		UHazeSplineComponentBase Spline = Cast<UHazeSplineComponentBase>(GetAttributeObject(n"SplineLockRef"));
		FVector SplineRightVector;

		if(Spline != nullptr)
			SplineRightVector = Spline.FindRightVectorClosestToWorldLocation(Player.GetActorLocation(), ESplineCoordinateSpace::World);

		FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);
		Input.Normalize();
		FVector GripNormal = ClimbingComponent.GripHitData.Normal;

		//if(Spline != nullptr)
		//	GripNormal = SplineRightVector;

		FRotator ControlRotation = Player.ControlRotation;

		FVector ControlRight = ControlRotation.RightVector;
		ControlRight = ControlRight.ConstrainToPlane(GripNormal);
		ControlRight.Normalize();

		FVector ControlUp = ControlRotation.UpVector;
		ControlUp = ControlUp.ConstrainToPlane(GripNormal);
		ControlUp.Normalize();

		FVector JumpDirection;
		JumpDirection = ControlUp * FMath::Clamp(Input.X, 0.4f, 1.f) + ControlRight * Input.Y * 0.6f ;

		if(Input.IsNearlyZero())
			JumpDirection = FVector(0.f, 0.f, 1.f);

		FVector JumpImpulse = JumpDirection * (ClimbingComponent.bIsSwinging ? ClimbingComponent.SwingJumpForce : ClimbingComponent.GripJumpForce);

		//FMath::VInterpTo(Player.GetActorLocation(), ClimbingComponent.GripHitData.ImpactPoint, DeltaTime, 3.f);

		// Directrion indicator
		System::DrawDebugLine(Player.GetActorCenterLocation(), (Player.GetActorCenterLocation() + (JumpDirection * 200.f)), FLinearColor(0.f,1.f,0.f), 0.f, 25.f);

		//Player.SetActorLocation(MoveToGrip.AccelerateTo(ClimbingComponent.GripHitData.ImpactPoint, 0.5f, DeltaTime) + (Player.GetActorLocation() - Player.GetActorCenterLocation()));

		if(WasActionStarted(ActionNames::MovementJump))
		{
			MoveComp.SetVelocity(0);
			Player.AddImpulse(JumpImpulse);
			
			/*
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Movement");

			FrameMove.OverrideStepUpHeight(0.f);
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.ApplyVelocity(JumpDirection * 500);

			MoveComp.Move(FrameMove);
			*/

			ClimbingComponent.bIsSwinging = false;
			ClimbingComponent.bHasGrip = false;
			ClimbingComponent.bCanJump = false;
		}
	}
}