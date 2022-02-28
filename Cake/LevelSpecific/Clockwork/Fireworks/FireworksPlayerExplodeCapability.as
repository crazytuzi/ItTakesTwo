import Cake.LevelSpecific.Clockwork.Fireworks.FireworksPlayerComponent;
import Cake.LevelSpecific.Clockwork.Fireworks.FireworkInteraction;
class UFireworksPlayerExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FireworksPlayerExplodeCapability");
	default CapabilityTags.Add(n"Fireworks");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFireworksPlayerComponent PlayerComp;

	AFireworkInteraction FireworkInteraction;

	float CurrentExplodeTime;
	float HoldExplodeRate;
	float StartExplodeRate = 0.2f;
	float EndExplodeRate = 0.02f;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UFireworksPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
        	return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::PrimaryLevelAbility))
        	return EHazeNetworkDeactivation::DontDeactivate;
		
		if (!WasActionStopped(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (FireworkInteraction == nullptr)
			FireworkInteraction = Cast<AFireworkInteraction>(GetAttributeObject(n"FireworkInteraction"));

		FireworkInteraction.SetExplodeButton(true);
		// FireworkInteraction.PlayExplodeRumble(Player);
	
		PlayerComp.bPressingRight = true;
		PlayerComp.FireworkManager.FireworkExplode(Player);
		HoldExplodeRate = StartExplodeRate;
		CurrentExplodeTime = HoldExplodeRate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.bPressingRight = false;
		FireworkInteraction.SetExplodeButton(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CurrentExplodeTime -= DeltaTime;

		if (CurrentExplodeTime <= 0.f)
		{
			PlayerComp.FireworkManager.FireworkExplode(Player);
			CurrentExplodeTime = HoldExplodeRate;
		}
		
		HoldExplodeRate = FMath::FInterpConstantTo(HoldExplodeRate, EndExplodeRate, DeltaTime, 0.3f);
	}
}