import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;
import Vino.Tutorial.TutorialStatics;

class UTreeBeetleRidingCancelCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");
	default CapabilityTags.Add(n"BeetleRidingCancel");

	UTreeBeetleRidingComponent BeetleRidingComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BeetleRidingComponent.bIsOnBeetle)
			return EHazeNetworkActivation::DontActivate;

//		if(WasActionStarted(ActionNames::Cancel))
//			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ShowCancelPrompt(Player, this);
//		
//		StopRidingBeetle(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveCancelPromptByInstigator(Player, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		if (!BeetleRidingComponent.Beetle.bIsRunning)
			StopRidingBeetle(Player);	
	}
}