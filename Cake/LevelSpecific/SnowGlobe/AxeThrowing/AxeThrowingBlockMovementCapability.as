import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;

class UAxeThrowingBlockMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingBlockMovementCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UAxeThrowingPlayerComp UserComp;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UAxeThrowingPlayerComp::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.TriggerMovementTransition(this);

		// Move player to interaction comp
		Player.MeshOffsetComponent.FreezeAndResetWithTime(0.4f);
		Player.SetActorTransform(UserComp.OurInteractionComp.WorldTransform);

		Player.BlockCapabilities(n"PlayerMarker", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockMovementSyncronization(this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);

		Player.UnblockCapabilities(n"PlayerMarker", this);
    }
}