import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingInteractStart;

class UCurlingPlayerInteractCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerInteractCancelCapability");
	default CapabilityTags.Add(n"CurlingPlayerInteract");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCurlingPlayerInteractComponent PlayerInteractComp;
	ACurlingInteractStart InteractStart;

	bool bActive;

	bool bCanCancel;

	FRotator RotationTarget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		PlayerInteractComp = UCurlingPlayerInteractComponent::Get(Player);

		bActive = true;
		bCanCancel = false;

		System::SetTimer(this, n"EnableCancel", 1.f, false);
	}

	UFUNCTION()
	void EnableCancel()
	{
		bCanCancel = true;

		if (PlayerInteractComp.InteractionState != EInteractionState::Cancelling && PlayerInteractComp.InteractionState != EInteractionState::Tutorial)
			PlayerInteractComp.InteractionState = EInteractionState::Interacting;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && !PlayerInteractComp.bTutorialActive && bCanCancel)
        	return EHazeNetworkActivation::ActivateFromControl;

       	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		InteractStart = Cast<ACurlingInteractStart>(GetAttributeObject(n"InteractStart"));
		
		if (bActive)
		{
			// InteractStart.PlayEndAnimation(Player, true);
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
			PlayerInteractComp.DeactivateCancelPrompt(Player);
			PlayerInteractComp.InteractionState = EInteractionState::Cancelling;
			bActive = false;
		}
	}
}