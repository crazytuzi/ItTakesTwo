import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingHardBrakeCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 102;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingFastSettings FastSettings;
	FIceSkatingHardBrakeSettings BrakeSettings;

	FVector BrakeForward;

	bool IsHoldingBackwards() const
	{
		FVector Velocity = MoveComp.Velocity;

		FVector VeloDirection = Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		FVector InputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		if (InputDirection.IsNearlyZero())
			return false;

		InputDirection.Normalize();

		float Angle = Math::DotToDegrees(InputDirection.DotProduct(-VeloDirection));
		return Angle < BrakeSettings.Angle;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

	    if (SkateComp.bIsFast)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsHoldingBackwards())
	        return EHazeNetworkActivation::DontActivate;

	    if (MoveComp.Velocity.SizeSquared() < FMath::Square(BrakeSettings.MinSpeed))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

	    if (SkateComp.bIsFast)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (!IsHoldingBackwards())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BrakeForward = MoveComp.Velocity.GetSafeNormal();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (MoveComp.Velocity.DotProduct(BrakeForward) < 0.f)
		{
			MoveComp.Velocity = -BrakeForward * (BrakeSettings.Impulse);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_FastBrake");

		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			Velocity -= Velocity.GetSafeNormal() * BrakeSettings.Force * DeltaTime;
			Velocity -= Velocity * BrakeSettings.Friction * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepDownHeight(5.f);
			FrameMove.FlagToMoveWithDownImpact();

			MoveCharacter(FrameMove, n"FastBrake");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"FastBrake");
		}	
	}
}
