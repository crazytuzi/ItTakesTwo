import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.StuckCharacter.CourtyardStuckCharacter;

class UCourtyardStuckCharacterCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;
	
	ACourtyardStuckCharacter Character;
	bool bFinishedAnimation = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Character = Cast<ACourtyardStuckCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Character.TargetStuckLocation == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bFinishedAnimation)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bFinishedAnimation = false;

		Character.CurrentStuckLocation.OnStuckCharacterPlayerCancelled.Clear();
		Character.CurrentStuckLocation.OnStuckCharacterButtonMashComplete.Clear();

		Character.CurrentStuckLocation.InteractionComp.OnActivated.UnbindObject(Character);

		if (Character.CurrentStuckLocation.CharacterAnimations.Release == nullptr)
			bFinishedAnimation = true;
		else
		{
			FHazeAnimationDelegate BlendedOut;
			BlendedOut.BindUFunction(this, n"OnBlendedOut");
			Character.PlaySlotAnimation(FHazeAnimationDelegate(), BlendedOut, Character.CurrentStuckLocation.CharacterAnimations.Release);
		}	
	}

	UFUNCTION()
	void OnBlendedOut()
	{
		bFinishedAnimation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Character.SetActorTransform(Character.TargetStuckLocation.CharacterLocation.ActorTransform);
		if (Character.TargetStuckLocation.CharacterAnimations.MH != nullptr)
		{
			FHazeSlotAnimSettings Settings;
			Settings.bLoop = true;
			Character.PlaySlotAnimation(Character.TargetStuckLocation.CharacterAnimations.MH, Settings);
		}
		
		Character.CurrentStuckLocation = Character.TargetStuckLocation;
		Character.TargetStuckLocation = nullptr;

		Character.LaunchAnimationComplete();

		Character.CurrentStuckLocation.InteractionComp.Enable(n"Empty");

		Character.CurrentStuckLocation.OnStuckCharacterPlayerCancelled.AddUFunction(Character, n"OnPlayerCancelled");
		Character.CurrentStuckLocation.OnStuckCharacterButtonMashComplete.AddUFunction(Character, n"LaunchCharacter");

		Character.CurrentStuckLocation.InteractionComp.OnActivated.AddUFunction(Character, n"OnInteractionActivated");
	}
}