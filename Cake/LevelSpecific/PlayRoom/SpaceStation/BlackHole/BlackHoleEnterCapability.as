
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.BlackHole.BlackHole;

class UBlackHoleEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ABlackHole BlackHole;

	int Index = 0;

	bool bEnterEventActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"BlackHole"))
        	return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration >= 2.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bEnterEventActivated = false;
		TArray<AActor> TempActors;
		Gameplay::GetAllActorsOfClass(ABlackHole::StaticClass(), TempActors);
		BlackHole = Cast<ABlackHole>(TempActors[0]);

		Player.SetCapabilityActionState(n"BlackHole", EHazeActionState::Inactive);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);

		FadeOutPlayer(Player, -1.f, 0.2f);

		Index = BlackHole.CurrentIndex;
		BlackHole.CurrentIndex++;
		if (BlackHole.CurrentIndex > BlackHole.MaxIndex)
			BlackHole.CurrentIndex = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);

		ClearPlayerFades(Player, 0.5f);

		BlackHole.OnExitBlackHole.Broadcast(Player, Index);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (ActiveDuration >= 0.25f && !bEnterEventActivated)
		{
			BlackHole.OnEnterBlackHole.Broadcast(Player, Index);
		}
	}
}