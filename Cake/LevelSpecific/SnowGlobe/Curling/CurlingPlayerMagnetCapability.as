import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;

class UCurlingPlayerMagnetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingMagnetCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UMagneticPlayerComponent MagnetComp;

	ACurlingStone CurlingStone;

	UCurlingStoneComponent StoneComp;

	bool bStartedThrow;

	UCurlingPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MagnetComp = UMagneticPlayerComponent::Get(Player);
		PlayerComp = UCurlingPlayerComp::Get(Player);

		if (MagnetComp == nullptr)
			return;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MagnetComp.GetActivatedMagnet() == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Default)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagnetComp.GetActivatedMagnet() != nullptr)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurlingStone = Cast<ACurlingStone>(MagnetComp.ActivatedMagnet.Owner);

		if (CurlingStone == nullptr)
			return;

		StoneComp = UCurlingStoneComponent::Get(CurlingStone);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CurlingStone = nullptr;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (CurlingStone == nullptr)
			return;

		if (StoneComp == nullptr)
			return;

		FVector Direction = (Player.ActorLocation - CurlingStone.ActorLocation).GetSafeNormal();
		FVector Acceleration = Direction * 1500.f * DeltaTime;

		CurlingStone.AddImpulse(Acceleration);
	}
}