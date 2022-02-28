import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;

class UHarpoonPlayerShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HarpoonPlayerShootCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHarpoonPlayerComponent PlayerComp;
	AMagnetHarpoonActor MagnetHarpoon;

	bool bCanFire;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHarpoonPlayerComponent::Get(Player);
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(GetAttributeObject(n"MagnetHarpoon"));
		bCanFire = false;

		System::SetTimer(this, n"DelayCanFire", 0.75f, false);
	}

	UFUNCTION()
	void DelayCanFire()
	{
		bCanFire = true;
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
        	return EHazeNetworkActivation::DontActivate;

		if (MagnetHarpoon == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (MagnetHarpoon.GetCatch())
        	return EHazeNetworkActivation::DontActivate;
        	
		if (!PlayerComp.bCanHarpoon)
			return EHazeNetworkActivation::DontActivate;

		if (PlayerComp.MagnetHarpoonState != EMagnetHarpoonState::Default)
			return EHazeNetworkActivation::DontActivate;

		if(!bCanFire)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (PlayerComp == nullptr)
			return;

		PlayerComp.FiredHarpoon();
		MagnetHarpoon.HarpoonSpearFired();

		PlayerComp.HidePrompts(Player);
		Player.SetAnimBoolParam(n"HarpoonFired", true);

		if (PlayerComp.AimWidget != nullptr)
			PlayerComp.AimWidget.BP_FiredHarpoon();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		UObject MH;
		ConsumeAttribute(n"MagnetHarpoon", MH);
    }
}