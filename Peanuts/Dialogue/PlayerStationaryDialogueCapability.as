import Peanuts.Dialogue.DialogueComponent;
import Peanuts.Dialogue.StationaryDialogueComponent;

class UPlayerStationaryDialogueCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Dialogue");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UDialogueComponent DialogueComp;
	UStationaryDialogueComponent StationaryDialogueComp;

	float DeactivationTimer;
	bool bWasBlendedIn = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DialogueComp = UDialogueComponent::GetOrCreate(Player);
		StationaryDialogueComp = UStationaryDialogueComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (StationaryDialogueComp.bIsInStationaryDialogue)
        	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (StationaryDialogueComp.bIsInStationaryDialogue)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bWasBlendedIn = false;
		DeactivationTimer = 1.f;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		Blend.OnCameraBlendFinished.AddUFunction(this, n"HandleCameraBlendedIn");
		StationaryDialogueComp.Camera.ActivateCamera(Player, Blend, this);
		Player.SetViewSize(EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Slow);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetViewSize(EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Slow);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		StationaryDialogueComp.Camera.DeactivateCamera(Player, 2.f);
		StationaryDialogueComp.OnFinished.ExecuteIfBound();
		StationaryDialogueComp.OnFinished.Clear();
	}

	UFUNCTION()
	void HandleCameraBlendedIn(UHazeCameraComponent Camera)
	{
		DialogueComp.bIsInDialogue = true;
		bWasBlendedIn = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!DialogueComp.bIsInDialogue && bWasBlendedIn)
		{
			DeactivationTimer -= DeltaTime;
			if (DeactivationTimer <= 0)
			{
				StationaryDialogueComp.bIsInStationaryDialogue = false;
			}
		}
	}

}