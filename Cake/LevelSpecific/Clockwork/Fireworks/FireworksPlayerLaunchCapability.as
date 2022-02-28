import Cake.LevelSpecific.Clockwork.Fireworks.FireworksPlayerComponent;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworkInteraction;

class UFireworksPlayerLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FireworksPlayerExplodeCapability");
	default CapabilityTags.Add(n"Fireworks");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFireworksPlayerComponent PlayerComp;

	AFireworkInteraction FireworkInteraction;

	bool bCanFire = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UFireworksPlayerComponent::Get(Player);
		bCanFire = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::SecondaryLevelAbility) || !bCanFire)
        	return EHazeNetworkActivation::DontActivate;		

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStopped(ActionNames::SecondaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (FireworkInteraction == nullptr)
			FireworkInteraction = Cast<AFireworkInteraction>(GetAttributeObject(n"FireworkInteraction"));
		
		FireworkInteraction.SetLaunchButton(true);
		FireworkInteraction.PlayShootRumble(Player);

		PlayerComp.FireworkManager.LaunchRocket();
		PlayerComp.bPressingLeft = true;

		bCanFire = false;

		System::SetTimer(this, n"DelayedEnableFire", 0.1f, false);
	}

	UFUNCTION()
	void DelayedEnableFire()
	{
		bCanFire = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.bPressingLeft = false;
		FireworkInteraction.SetLaunchButton(false);
	}
}