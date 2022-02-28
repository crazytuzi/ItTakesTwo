import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingTuckCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingTuckSettings TuckSettings;
	float HoldTimer = 0.f;

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

	    if (HoldTimer < TuckSettings.HoldDelay)
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

	    if (HoldTimer < TuckSettings.HoldDelay)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

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
	void PreTick(float DeltaTime)
	{
		if (IsActioning(ActionNames::MovementDash))
		{
			HoldTimer += DeltaTime;
		}
		else
		{
			HoldTimer = 0.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Tuck");

		if (HasControl())
		{
			FVector Input = SkateComp.GetScaledPlayerInput_VelocityRelative();

			// Turn it!
			FVector Velocity = MoveComp.Velocity;
			Velocity = SkateComp.Turn(Velocity, Input.Y * TuckSettings.TurnSpeed * DeltaTime);

			// If above max speed, brake it down
			{
				float Speed = Velocity.Size();
				if (Speed > TuckSettings.MaxSpeed)
				{
					float ExtraSpeed = Speed - TuckSettings.MaxSpeed;
					Velocity -= Velocity.GetSafeNormal() * ExtraSpeed * TuckSettings.MaxSpeedBrake * DeltaTime;
				}
			}

			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepDownHeight(5.f);

			MoveCharacter(FrameMove, n"SkateTuck");
			CrumbComp.SetCustomCrumbVector(Input);

			//FHazeActorReplication ReplicationParams = Player.MakeReplicationData();
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"SkateTuck");
		}
	}
}