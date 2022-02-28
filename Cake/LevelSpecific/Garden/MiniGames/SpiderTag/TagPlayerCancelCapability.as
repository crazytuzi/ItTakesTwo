import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagCancelComp;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagStartingPoint;
class UTagPlayerCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TagPlayerCancelCapability");
	default CapabilityTags.Add(n"Tag");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"TagMinigame";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UTagCancelComp TagCancelComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TagCancelComp = UTagCancelComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && TagCancelComp.bCanCancel)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ATagStartingPoint StartingPoint = Cast<ATagStartingPoint>(TagCancelComp.TagStartingPointObj);

		if (StartingPoint == nullptr)
			return;
			
		StartingPoint.OnCancelInteraction(StartingPoint.InteractionComp, Player);	
		TagCancelComp.RemovePlayerCancel(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		TagCancelComp.RemovePlayerCancel(Player);
	}
}