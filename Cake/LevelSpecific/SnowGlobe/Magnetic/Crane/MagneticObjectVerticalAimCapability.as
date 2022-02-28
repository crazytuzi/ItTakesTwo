// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetDirectionObjectComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

// class UMagneticObjectVerticalAimCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(n"MagnetCapability");
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

// 	AActor Player;
//     UPrimitiveComponent MeshComponent;
// 	UMagnetDirectionObjectComponent MagnetComponent;
// 	USceneComponent VerticalAimComponent;

// 	float MaxPitchRotation = 1;
// 	float MinPitchRotation = 0;
 
// 	float MinDistance = 300;
// 	float MaxDistance = 1500;

// 	float HowMuchRotationToAdd = 0;
// 	float DistancePercentage;
// 	float AddedPitchRotation = 0.0f;

// 	const float RotationSpeed = 10;
	

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
//         MagnetComponent = UMagnetDirectionObjectComponent::Get(Owner);
//         MeshComponent = Cast<UPrimitiveComponent>(Owner.RootComponent);
// 		VerticalAimComponent = MagnetComponent.VerticalAimComponent;
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

//         else
//             return EHazeNetworkDeactivation::DeactivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		if(VerticalAimComponent == nullptr)
// 			VerticalAimComponent = MagnetComponent.VerticalAimComponent;
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MagnetComponent.UsingPlayers.Num() <= 0)
// 			return;

// 		float TotalDistancePercentage = 0.0f;
// 		for(AHazePlayerCharacter Player : MagnetComponent.UsingPlayers)
// 		{
// 			float Distance = 0.0f;
// 			float PlayerDistancePercentage = 0.0f;
// 			FVector MagnetLocation = MagnetComponent.WorldLocation;
// 			MagnetLocation.Z = 0.0f;
// 			FVector PlayerLocation = Player.ActorLocation;
// 			PlayerLocation.Z = 0.0f;
// 			float PlayerDistance = (MagnetLocation - PlayerLocation).Size();

// 			int Index = MagnetComponent.UsingPlayers.FindIndex(Player);


// 			Distance += PlayerDistance;
// 			PlayerDistancePercentage = (Distance - MinDistance) / (MaxDistance - MinDistance);
// 			PlayerDistancePercentage = FMath::Clamp(PlayerDistancePercentage, 0.0f, 1.0f);

// 			if(MagnetComponent.bPushing[Index])
// 				PlayerDistancePercentage *= -1.0f;

// 			TotalDistancePercentage += PlayerDistancePercentage;
// 		}

// 		DistancePercentage = TotalDistancePercentage;

// 		UpdateVerticalCompRotation(DeltaTime);
// 	}

// 	void UpdateVerticalCompRotation(float DeltaTime)
// 	{
// 		float PitchPercentage = (AddedPitchRotation - MinPitchRotation) / (MaxPitchRotation - MinPitchRotation);

// 		float CurRotationSpeed;
// 		if(FMath::IsNearlyEqual(PitchPercentage, DistancePercentage, 0.1))
// 		{
// 			return;
// 		}
// 		if(PitchPercentage < DistancePercentage)
// 		{
// 			CurRotationSpeed = RotationSpeed;
// 		}
// 		else if(PitchPercentage > DistancePercentage)
// 		{
// 			CurRotationSpeed = -RotationSpeed;
// 		}

// 		float RotationToAdd = CurRotationSpeed * DeltaTime;
// 		float HypotheticalRotation = AddedPitchRotation + RotationToAdd;

// 		if(HypotheticalRotation >= MinPitchRotation && HypotheticalRotation <= MaxPitchRotation)
// 		{
// 			FRotator RotatorToAdd = FRotator(RotationToAdd, 0, 0);
// 			AddedPitchRotation += RotationToAdd;
// 			//VerticalAimComponent.AddLocalRotation(RotatorToAdd);
// 		}
// 	}
// }