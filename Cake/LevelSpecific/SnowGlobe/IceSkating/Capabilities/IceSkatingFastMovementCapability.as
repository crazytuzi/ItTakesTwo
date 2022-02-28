import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingFastMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::AudioMovementEfforts);
	default CapabilityTags.Add( n"IceSkatingMovement");
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 106;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingFastSettings FastSettings;

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

	    if (!SkateComp.bIsFast)
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

	    if (!SkateComp.bIsFast)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Fast");
		FVector Input = SkateComp.GetScaledPlayerInput_VelocityRelative();

		if (HasControl())
		{
			// Calculate how fast we should be turning based on how fast we're going (from flat ground max speed to sloped max speed)
			float Speed = MoveComp.Velocity.Size();
			float SpeedPercent = Math::GetPercentageBetweenClamped(FastSettings.MaxSpeed_Flat, FastSettings.MaxSpeed_Slope, Speed);

			float TurnSpeed = FMath::Lerp(FastSettings.TurnSpeed_Max, FastSettings.TurnSpeed_Min, SpeedPercent);

			// Turn it!
			FVector Velocity = SkateComp.TransformVectorToGround(MoveComp.Velocity);
			Velocity = SkateComp.Turn(Velocity, Input.Y * TurnSpeed * DeltaTime);

			// Brake if going above max speed
			if (Speed > SkateComp.MaxSpeed)
			{
				Velocity = SkateComp.ApplyMaxSpeedFriction(Velocity, DeltaTime);
			}
			// ... or accelerate if going below it
			else if (Input.X > 0.f)
			{
				Speed = FMath::Lerp(Speed, SkateComp.MaxSpeed, FastSettings.MaxSpeedAcceleration * Input.X * DeltaTime);
				Velocity = Velocity.GetSafeNormal() * Speed;
			}

			// Braking
			if (Input.X < 0.f)
			{
				Velocity -= Velocity * FastSettings.BrakeCoeff * DeltaTime;
			}

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepDownHeight(120.f);
			FrameMove.FlagToMoveWithDownImpact();

			MoveCharacter(FrameMove, n"IceSkating");
			CrumbComp.SetCustomCrumbVector(Input);
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