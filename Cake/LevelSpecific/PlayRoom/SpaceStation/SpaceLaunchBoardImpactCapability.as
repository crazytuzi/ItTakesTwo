import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceLaunchBoard;

class USpaceLaunchBoardImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

    float FallDistance;

    ASpaceLaunchBoard CurLaunchBoard;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"LaunchBoardImpact"))
            return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateFromControl;
		// return EHazeNetworkDeactivation::DeactivateLocal;
		// return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        CurLaunchBoard = Cast<ASpaceLaunchBoard>(GetAttributeObject(n"SpaceLaunchBoard"));
        Player.SetCapabilityActionState(n"LaunchBoardImpact", EHazeActionState::Inactive);
        FallDistance = GetAttributeValue(n"GroundPoundFallDistance");

        CurLaunchBoard.TriggerImpact(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}