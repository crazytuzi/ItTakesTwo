// import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeMarbleActor;

// class UTrapezeMarblePostThrowOutOfSightShredderCapability : UHazeCapability
// {
// 	ATrapezeMarbleActor MarbleOwner;

// 	bool bMarbleShouldDie;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		MarbleOwner = Cast<ATrapezeMarbleActor>(Owner);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(bMarbleShouldDie)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!MarbleOwner.IsAirborne())
// 			return EHazeNetworkActivation::DontActivate;

// 		if(MarbleOwner.IsFlyingTowardsDispenser())
// 			return EHazeNetworkActivation::DontActivate;

// 		return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(HasControl() && SceneView::IsFullScreen() && !MarbleOwner.WasRecentlyRendered())
// 			NetSetMarbleShouldDie();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(bMarbleShouldDie)
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		if(!MarbleOwner.IsAirborne())
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		if(MarbleOwner.IsFlyingTowardsDispenser())
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		if(MarbleOwner.IsAirborne())
// 		{
// 			MarbleOwner.StopMoving();
// 			MarbleOwner.LandMarbleAfterThrow();
// 		}

// 		bMarbleShouldDie = false;
// 	}

// 	UFUNCTION(NetFunction)
// 	void NetSetMarbleShouldDie()
// 	{
// 		bMarbleShouldDie = true;
// 	}
// }