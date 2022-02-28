import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossWalkTogetherComponent;

class UClockworkLastBossWalkTogetherCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ClockworkLastBossWalkTogetherCapability");
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"ClockworkLastBossWalkTogetherCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UClockworkLastBossWalkTogetherComponent WalkComp;
	UHazeMovementComponent MoveComp;
	UMovementSettings MovementSettings;

	bool bHasBlockedMovement = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MovementSettings = UMovementSettings::GetSettings(Owner);
		WalkComp = UClockworkLastBossWalkTogetherComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(n"WalkTogether"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"WalkTogether"))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
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
		// if (WalkComp.WalkTogetherManager.GetActorInFirstPlace() != Player)
		// {
		// 	BlockMovement(false);
		// 	return;
		// }

		// if (WalkComp.WalkTogetherManager.DistanceBetweenPlayers() > 2000.f)
		// 	BlockMovement(true);
		// else 
		// 	BlockMovement(false);
		
	}

	void BlockMovement(bool bShouldBlock)
	{
		if (bShouldBlock && !bHasBlockedMovement)
		{
			bHasBlockedMovement = true;
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}

		if (!bShouldBlock && bHasBlockedMovement)
		{
			bHasBlockedMovement = false;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}
	}
}