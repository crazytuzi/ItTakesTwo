
// import Vino.Movement.Components.MovementComponent;
// import Vino.Movement.MovementSystemTags;

// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.LargePacket.MagneticLargePacket;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPhysicalComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// class UMagneticLargePacketGroundMoveCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
// 	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);
// 	default CapabilityTags.Add(MovementSystemTags::Falling);	

// 	default TickGroup = ECapabilityTickGroups::LastMovement;

// 	default CapabilityDebugCategory = CapabilityTags::Movement;

// 	UHazePhysicalMovementComponent MovementComponent;
// 	AMagneticLargePacket PacketOwner;
// 	float OriginalGravityAmount = 0;
// 	bool bShouldBeActive = false;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		PacketOwner = Cast<AMagneticLargePacket>(Owner);
//      	MovementComponent = UHazePhysicalMovementComponent::Get(Owner);
// 		OriginalGravityAmount = MovementComponent.GravityScale;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
// 		bShouldBeActive = false;
// 		if(!IsBlocked())
// 		{
// 			bShouldBeActive = PacketOwner.GetInfluencingPlayerCount() == 0;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(MovementComponent.bSimulationEnabled == false)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!bShouldBeActive)
// 			return EHazeNetworkActivation::DontActivate;
		
// 		return EHazeNetworkActivation::ActivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(MovementComponent.bSimulationEnabled == false)
// 			return EHazeNetworkDeactivation::DeactivateLocal;

// 		if(!bShouldBeActive)
// 			return EHazeNetworkDeactivation::DeactivateLocal;
		
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		MovementComponent.GravityScale = OriginalGravityAmount;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		MovementComponent.GravityScale = 0.f;
// 	}


// }