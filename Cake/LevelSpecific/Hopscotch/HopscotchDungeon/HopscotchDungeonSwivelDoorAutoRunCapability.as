import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSwiverDoorComponent;

class UHopscotchDungeonSwivelDoorAutoRunCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HopscotchDungeonSwivelDoorAutoRunCapability");

	default CapabilityDebugCategory = n"HopscotchDungeonSwivelDoorAutoRunCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHopscotchDungeonSwivelDoorComponent DoorComp;
	float AutoRunDuration = 0.f;
	float AutoRunTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DoorComp = UHopscotchDungeonSwivelDoorComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!Player.HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(n"DoneWithDoor"))
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!IsActioning(n"DoneWithDoor"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"Dash", this);
		Player.BlockCapabilities(n"Jump", this);
		Player.BlockCapabilities(n"GroundPound", this);
		AutoRunDuration = DoorComp.SwivelDoor.AutoMoveDuration;
		SetNewSwivelDoor(Player, nullptr);
		AutoMoveCharacterForwards(Player, AutoRunDuration, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Dash", this);
		Player.UnblockCapabilities(n"Jump", this);
		Player.UnblockCapabilities(n"GroundPound", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AutoRunTimer += DeltaTime;
		if (AutoRunTimer >= AutoRunDuration)
		{
			Player.SetCapabilityActionState(n"DoneWithDoor", EHazeActionState::Inactive);
		}
	}
}