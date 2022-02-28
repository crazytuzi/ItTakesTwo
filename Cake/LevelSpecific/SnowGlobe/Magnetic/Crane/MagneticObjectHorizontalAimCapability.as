// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetDirectionObjectComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// class UMagneticObjectHorizontalAimCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	AActor Player;
//     UPrimitiveComponent MeshComponent;
// 	UMagnetDirectionObjectComponent MagnetComponent;

// 	USceneComponent HorizontalAimComponent;

// 	float AngularVelocity = 0.0f;
// 	float Drag = 10.0f;
// 	float Acceleration = 2.5f;

// 	float AddedRotation = 0.0f;	

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
//         MagnetComponent = UMagnetDirectionObjectComponent::Get(Owner);
//         MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
// 		HorizontalAimComponent = MagnetComponent.HorizontalAimComponent;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
//         if (IsActioning(n"MagneticInteraction"))
// 			return EHazeNetworkActivation::ActivateFromControl;
        
//         else
//             return EHazeNetworkActivation::DontActivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (IsActioning(n"MagneticInteraction"))
//             return EHazeNetworkDeactivation::DontDeactivate;

// 		if(!FMath::IsNearlyZero(AngularVelocity, 0.1f))
//             return EHazeNetworkDeactivation::DontDeactivate;

//         else
//             return EHazeNetworkDeactivation::DeactivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		if(HorizontalAimComponent == nullptr)
// 			HorizontalAimComponent = MagnetComponent.HorizontalAimComponent;
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		for(AHazePlayerCharacter Player : MagnetComponent.UsingPlayers)
// 		{
// 			FVector ToMagnetDir = MagnetComponent.WorldLocation - MagnetComponent.Owner.ActorLocation;
// 			FVector ToPlayerDir = Player.ActorLocation - MagnetComponent.WorldLocation;

// 			FVector Forward = MagnetComponent.Owner.ActorUpVector.CrossProduct(ToMagnetDir);
// 			Forward.Normalize();
// 			float Force = ToPlayerDir.DotProduct(Forward);

// 			int Index = MagnetComponent.UsingPlayers.FindIndex(Player);
// 			if(MagnetComponent.bPushing[Index])
// 			{
// 				Force = -Force * 0.25f;	
// 			}
				
// 			AngularVelocity += Force * Acceleration * DeltaTime;
// 		}

// 		AngularVelocity -= AngularVelocity * Drag * DeltaTime;

// 		if (HorizontalAimComponent.RelativeRotation.Yaw > 0 && AngularVelocity * DeltaTime > 0)
// 		{
// 			return;
// 		}

// 		if (HorizontalAimComponent.RelativeRotation.Yaw < -160 && AngularVelocity * DeltaTime < 0)
// 		{
// 			return;
// 		}

// 		HorizontalAimComponent.AddLocalRotation(FRotator(0,  AngularVelocity *  DeltaTime, 0));
// 		AddedRotation += AngularVelocity *  DeltaTime;
		
// 	}
// }