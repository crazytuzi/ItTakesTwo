import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCameraComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingCustomVelocityCalculator;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingSlowMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add( n"IceSkatingMovement");
	default CapabilityTags.Add(MovementSystemTags::AudioMovementEfforts);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 107;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;
	UIceSkatingCameraComponent SkateCamComp;
	
	FIceSkatingSlowSettings SlowSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		SkateCamComp = UIceSkatingCameraComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Slow");
		FrameMove.OverrideStepDownHeight(120.f);
		FVector Input = SkateComp.GetScaledPlayerInput();

		if (HasControl())
		{
			// Calculate the slope multiplier, so we don't accelerate if we're trying to go up slopes
			float SlopeMultiplier = 0.f;
			FVector SlopeInput = SkateComp.TransformVectorToGround(Input);

			// We want to limit our acceleration going up slopes
			float Slope = SlopeInput.DotProduct(FVector::UpVector);
			float MaxSlopeSin = FMath::Sin(SlowSettings.MaxSlope * DEG_TO_RAD);

			SlopeMultiplier = 1.f - Math::Saturate(Slope / MaxSlopeSin);

			// Apply forces!
			FVector Velocity = SkateComp.TransformVectorToGround(MoveComp.Velocity);

			Velocity += SlopeInput * SlowSettings.Acceleration * SlopeMultiplier * DeltaTime;

			// We want more friction the further away from the velocity we're inputting
			float InputFrictionAlpha = Input.DotProduct(Velocity.GetSafeNormal());
			InputFrictionAlpha = InputFrictionAlpha / 2.f + 0.5f; // [-1, 1] => [0, 1]
			float Friction = FMath::Lerp(SlowSettings.Friction_Min, SlowSettings.Friction_Max, InputFrictionAlpha);

			Velocity -= Velocity * Friction * DeltaTime;
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.FlagToMoveWithDownImpact();
			MoveCharacter(FrameMove, n"IceSkating");

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"IceSkating");
		}
	}
}