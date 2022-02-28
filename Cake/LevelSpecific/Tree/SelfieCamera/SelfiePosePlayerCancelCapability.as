import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePosePlayerComp;
class USelfiePosePlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfiePosePlayerCancelCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USelfiePosePlayerComp PlayerComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USelfiePosePlayerComp::Get(Player);
		
		//Prevents spam as that looks weird AF
		PlayerComp.bCanCancel = false;
		System::SetTimer(this, n"DelayAllowCancel", 0.45f, false);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (WasActionStarted(ActionNames::Cancel) && PlayerComp.bCanCancel)
			return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		PlayerComp.OnPlayerCancelledPoseEvent.Broadcast(Player);
		PlayerComp.HidePlayerCancel(Player);
	}

	UFUNCTION()
	void DelayAllowCancel()
	{
		PlayerComp.ShowPlayerCancel(Player);
		PlayerComp.bCanCancel = true;
	}
}