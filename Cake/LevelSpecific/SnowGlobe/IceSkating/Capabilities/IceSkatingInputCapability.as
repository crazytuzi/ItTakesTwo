import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingInputCapability : UHazeCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	bool bIsGroundPoundBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		CrumbComp = UHazeCrumbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		SetGroundPoundBlocked(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SkateComp.InputPauseGraceTimer -= DeltaTime;

		// Update input pausing
		if (MoveComp.IsAirborne())
		{
			SkateComp.InputPauseTimer -= DeltaTime;
		}
		// Don't ground-reset the timer if we're in the grace period..
		else if (SkateComp.InputPauseGraceTimer < 0.f)
		{
			// Reset input pausing when becoming grouded
			SkateComp.InputPauseTimer = -1.f;
			SkateComp.InputPauseDuration = -1.f;
		}

		if (HasControl())
		{
			SkateComp.PlayerInputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			CrumbComp.SetCustomCrumbVector(SkateComp.PlayerInputDirection);
		}
		else
		{
			// On slave-side, get last valid crumb and check the custom vector (which should be set to input)
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.GetCurrentReplicatedData(CrumbData);

			SkateComp.PlayerInputDirection = CrumbData.CustomCrumbVector;
		}

		SkateComp.bHasMovementInput = !SkateComp.GetScaledPlayerInput().IsNearlyZero();
		SetGroundPoundBlocked(SkateComp.InputPauseTimer > 0.f);
	}

	void SetGroundPoundBlocked(bool bBlocked)
	{
		if (bIsGroundPoundBlocked == bBlocked)
			return;

		if (bBlocked)
			Owner.BlockCapabilities(MovementSystemTags::GroundPound, this);
		else
			Owner.UnblockCapabilities(MovementSystemTags::GroundPound, this);

		bIsGroundPoundBlocked = bBlocked;
	}
}