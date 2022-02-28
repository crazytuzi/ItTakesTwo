import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;

class UWhackACodyEnterCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");
	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UWhackACodyComponent WhackaComp;

	UPlayerHazeAkComponent CodyAkComp;
	UAkAudioEvent EnterWhackACody;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);

		CodyAkComp = UPlayerHazeAkComponent::Get(Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (WhackaComp.bHasEntered)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (WhackaComp.bHasEntered)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeMoveToDestinationSettings Settings;
		FHazeDestinationEvents Events;
		Events.OnDestinationReached.BindUFunction(this, n"HandleMoveToFinished");

		USceneComponent MoveToTarget = WhackaComp.WhackABoardRef.CodyWalkToLocation;
		Game::GetCody().MoveTo(MoveToTarget.WorldTransform, WhackaComp.WhackABoardRef, Settings, Events);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION()
	void HandleMoveToFinished(AHazeActor Actor)
	{
		WhackaComp.bHasEntered = true;
	}
}
