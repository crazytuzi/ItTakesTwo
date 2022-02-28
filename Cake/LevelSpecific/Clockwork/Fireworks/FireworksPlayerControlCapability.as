import Cake.LevelSpecific.Clockwork.Fireworks.FireworksPlayerComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlParams;

class UFireworksPlayerControlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FireworksPlayerExplodeCapability");
	default CapabilityTags.Add(n"Fireworks");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFireworksPlayerComponent PlayerComp;

	bool bCanCancel;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UFireworksPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && bCanCancel)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		Player.BlockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);
		Player.TriggerMovementTransition(this);
		
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.75f;
		PlayerComp.HazeCameraActor.ActivateCamera(Player, Blend, this);
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Slow);
		
		PlayerComp.bIsExiting = false;

		PlayerComp.ShowRightTriggerPrompt(Player);
		PlayerComp.ShowLeftTriggerPrompt(Player);
		PlayerComp.ShowInteractionCancel(Player);

		bCanCancel = false;

		System::SetTimer(this, n"EnableCancel", 0.5f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(TimeControlCapabilityTags::TimeSequenceCapability, this);
		Player.UnblockCapabilities(TimeControlCapabilityTags::TimeControlCapability, this);

		PlayerComp.HazeCameraActor.DeactivateCamera(Player, 1.4f);
		PlayerComp.PlayerCancel.Execute(Player);
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Slow);

		PlayerComp.HideTutorialPrompts(Player);
		PlayerComp.bIsExiting = true;
	}

	UFUNCTION()
	void EnableCancel()
	{
		bCanCancel = true;
	}
}