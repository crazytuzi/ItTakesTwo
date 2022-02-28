import Vino.Interactions.InteractionComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.StuckCharacter.CourtyardStuckCharacterInteraction;
import Vino.Tutorial.TutorialStatics;

class UCourtyardStuckCharacterPlayerCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;
	
	AHazePlayerCharacter Player;
	UInteractionComponent InteractionComp;

	ACourtyardStuckCharacterInteraction StuckCharacterInteraction;

	bool bCanCancel = false;

	UButtonMashProgressHandle ButtonMashHandle;
	float ButtonMashDecay = 0.25f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Cast<ACourtyardStuckCharacterInteraction>(GetAttributeObject(n"StuckCharacterInteraction")) == nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bCanCancel && WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (ButtonMashHandle != nullptr && ButtonMashHandle.Progress >= 1.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"StuckCharacterInteraction", GetAttributeObject(n"StuckCharacterInteraction"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bCanCancel = false;

		Player.TriggerMovementTransition(Instigator = this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		StuckCharacterInteraction = Cast<ACourtyardStuckCharacterInteraction>(ActivationParams.GetObject(n"StuckCharacterInteraction"));		
		UObject Out;
		ConsumeAttribute(n"StuckCharacterInteraction", Out);		

		if (StuckCharacterInteraction.PlayerAnimations[Player].Enter != nullptr)
		{
			FHazeAnimationDelegate Finished;
			Finished.BindUFunction(this, n"OnEnterFinished");
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), Finished, StuckCharacterInteraction.PlayerAnimations[Player].Enter);
		}
		else
			bCanCancel = true;
	}

	UFUNCTION()
	void OnEnterFinished()
	{
		ButtonMashHandle = StartButtonMashProgressAttachToComponent(Player, StuckCharacterInteraction.CharacterLocation.RootComponent, NAME_None, FVector::UpVector * 200.f);
		bCanCancel = true;

		ShowCancelPrompt(Player, this);

		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), StuckCharacterInteraction.PlayerAnimations[Player].MH, true);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if (WasActionStarted(ActionNames::Cancel))
			OutParams.AddActionState(n"WasCancelled");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		bool bCancelled = DeactivationParams.GetActionState(n"WasCancelled");
		if (bCancelled)
			StuckCharacterInteraction.CancelInteraction(Player);
		else
			StuckCharacterInteraction.CompletedInteraction(Player);

		StopButtonMash(ButtonMashHandle);

		RemoveCancelPromptByInstigator(Player, this);
		
		Player.StopAllSlotAnimations();
		UAnimSequence Animation = bCancelled ? StuckCharacterInteraction.PlayerAnimations[Player].Cancel : StuckCharacterInteraction.PlayerAnimations[Player].Throw;
		Player.PlayEventAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Animation);
		
		StuckCharacterInteraction = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ButtonMashHandle != nullptr)
		{
			float MashRate = ButtonMashHandle.MashRateControlSide * 0.12f;		
			ButtonMashHandle.Progress -= ButtonMashDecay * DeltaTime;
			ButtonMashHandle.Progress += MashRate * DeltaTime;
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_StuckKnight_MashRate", MashRate);
		}
	}
}