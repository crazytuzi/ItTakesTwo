// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticSharkComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Shark.MagneticSharkActor;

// class UPlayerMagneticSharkCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 1;

// 	AHazePlayerCharacter Player;
// 	UMagneticPlayerComponent PlayerMagnetComp;

// 	UMagneticSharkComponent ActivatedMagnet;

// 	AMagneticSharkActor CurrentShark; 

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!HasControl())
// 			return EHazeNetworkActivation::DontActivate;

// 		UMagneticSharkComponent CurrentTargetedMagnet = Cast<UMagneticSharkComponent>(PlayerMagnetComp.GetTargetedMagnet());
// 		if(CurrentTargetedMagnet == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
// 			return EHazeNetworkActivation::DontActivate;
		

// 		return EHazeNetworkActivation::ActivateUsingCrumb;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(!PlayerMagnetComp.MagnetLockonIsActivatedBy(this))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		if(!IsActioning(ActionNames::PrimaryLevelAbility))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
// 	{
// 		ActivationParams.AddObject(n"CurrentMagnet", PlayerMagnetComp.GetTargetedMagnet());
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		Player.BlockCapabilities(FMagneticTags::MagneticControl, this);

// 		ActivatedMagnet = Cast<UMagneticSharkComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
// 		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);

// 		ActivatedMagnet.UsingPlayers.Add(Player);
// 		ActivatedMagnet.bOpposite.Add(PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet));

// 		CurrentShark = Cast<AMagneticSharkActor>(ActivatedMagnet.Owner); 
// 		CurrentShark.bAffectedByMagnet = true;
// 	}
 
// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Player.UnblockCapabilities(FMagneticTags::MagneticControl, this);
// 		PlayerMagnetComp.DeactivateMagnetLockon(this);

// 		int PlayerIndex = ActivatedMagnet.UsingPlayers.FindIndex(Player);

// 		ActivatedMagnet.bOpposite.RemoveAt(PlayerIndex);
// 		ActivatedMagnet.UsingPlayers.Remove(Player);
		

// 		ActivatedMagnet = nullptr; 
// 		CurrentShark.bAffectedByMagnet = false;
// 		CurrentShark = nullptr;
// 	}
// }