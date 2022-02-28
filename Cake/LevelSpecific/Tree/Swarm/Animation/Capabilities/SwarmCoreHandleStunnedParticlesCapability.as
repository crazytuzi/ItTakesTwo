//
//import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
//
//class USwarmCoreHandleStunnedParticlesCapability : UHazeCapability
//{
//	default CapabilityTags.Add(n"Swarm");
//	default CapabilityTags.Add(n"SwarmCore");
//
//	// We probably want to tick this in the beginning,
//	// before the animation, otherwise we might tick it 
//	// early just after the AnimNotify adds it to the array.
//	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;
//
//	ASwarmActor SwarmActor = nullptr;
//
//	UFUNCTION(BlueprintOverride)
//	void Setup(FCapabilitySetupParams SetupParams)
//	{
//		SwarmActor = Cast<ASwarmActor>(Owner);
//	}
//
//	UFUNCTION(BlueprintOverride)
//	EHazeNetworkActivation ShouldActivate() const
//	{
//		if(SwarmActor.AreAnyParticlesAlive())
//			return EHazeNetworkActivation::ActivateFromControl;
//		return EHazeNetworkActivation::DontActivate;
//	}
//
//	UFUNCTION(BlueprintOverride)
//	EHazeNetworkDeactivation ShouldDeactivate() const
//	{
//		if(!SwarmActor.AreAnyParticlesAlive())
// 			return EHazeNetworkDeactivation::DeactivateFromControl;
// 		return EHazeNetworkDeactivation::DontDeactivate;
//	}
//}
