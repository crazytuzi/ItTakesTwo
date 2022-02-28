import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

class UParentBlobButtonHoldPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ParentBlobButtonHold");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	const FName ActionToUse = ActionNames::InteractionTrigger;

	AHazePlayerCharacter Player;
	UParentBlobButtonHoldComponent HoldComp;
	UParentBlobPlayerComponent ParentBlobComponent;
	AParentBlob ParentBlob;
	
	bool bHolding = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ParentBlobComponent = UParentBlobPlayerComponent::Get(Player);
		ParentBlob = ParentBlobComponent.ParentBlob;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{ 
		if (ParentBlob == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UParentBlobButtonHoldComponent ButtonHoldComp = UParentBlobButtonHoldComponent::Get(ParentBlob);
		if (!ButtonHoldComp.bButtonHoldActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ParentBlob == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		UParentBlobButtonHoldComponent ButtonHoldComp = UParentBlobButtonHoldComponent::Get(ParentBlob);
		if (!ButtonHoldComp.bButtonHoldActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"ParentBlobButtonHold", true);
		HoldComp = UParentBlobButtonHoldComponent::Get(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"ParentBlobButtonHold", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bHolding = IsActioning(ActionToUse);
		HoldComp.SetPlayerHoldStatus(Player, bHolding);
	}
}