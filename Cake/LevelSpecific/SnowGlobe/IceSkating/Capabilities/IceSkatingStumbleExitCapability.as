import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingStumbleExitCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 50;

	default SeperateInactiveTick(ECapabilityTickGroups::BeforeMovement, 5);

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingStumbleSettings StumbleSettings;
	float StumbleTime = 0.f;

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

	    FHitResult GroundHit = MoveComp.DownHit;
	    if (!GroundHit.bBlockingHit)
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

		if (IsSurfaceIceSkateable(GroundHit))
	        return EHazeNetworkActivation::DontActivate;

	    float HorizontalSpeed = MoveComp.Velocity.ConstrainToPlane(GroundHit.Normal).Size();
	    if (HorizontalSpeed < StumbleSettings.MinStumbleSpeed)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	    if (StumbleTime >= StumbleSettings.Duration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StumbleTime = 0.f;
		Player.PlayForceFeedback(SkateComp.StumbleEffect, false, true, n"IceSkatingStumble");

		Player.AddLocomotionFeature(SkateComp.StumbleFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveLocomotionFeature(SkateComp.StumbleFeature);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StumbleTime += DeltaTime;
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Stumble");
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if (!Input.IsNearlyZero())
			{
				float TurnMultiplier = Math::Saturate(StumbleTime / StumbleSettings.TurnEnableTime);
				Velocity = Math::SlerpVectorTowards(Velocity, Input, StumbleSettings.TurnRate * TurnMultiplier * DeltaTime);
			}

			Velocity -= Velocity * StumbleSettings.Friction * DeltaTime;

			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(FrameMove, n"IceSkatingStumble");
		CrumbComp.LeaveMovementCrumb();
	}
}