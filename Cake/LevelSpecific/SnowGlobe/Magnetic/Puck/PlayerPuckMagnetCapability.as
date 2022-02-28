import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class UPlayerPuckMagnetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;
	UMagnetGenericComponent MagneticComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		UMagnetGenericComponent CurrentTargetedMagnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
			return EHazeNetworkActivation::DontActivate;

	//	if(!PlayerMagnetComp.HasOppositePolarity(CurrentTargetedMagnet))
	//	 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerMagnetComp.MagnetLockonIsActivatedBy(this))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		UMagnetGenericComponent CurrentActiveMagnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.GetActivatedMagnet());
	//	if(!PlayerMagnetComp.HasOppositePolarity(CurrentActiveMagnet))
	//		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(CurrentActiveMagnet != nullptr)
		{
			FVector GrabLocation = CurrentActiveMagnet.GetTransformFor(Player).Location;
			float Distance = Player.ActorLocation.Distance(GrabLocation);
			if(Distance > 2000.f)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
	
		return EHazeNetworkDeactivation::DontDeactivate;

	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"CurrentMagnet", PlayerMagnetComp.GetTargetedMagnet());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMagnetGenericComponent ActivatedMagnet = Cast<UMagnetGenericComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);

		MagneticComponent = ActivatedMagnet;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerMagnetComp.DeactivateMagnetLockon(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}