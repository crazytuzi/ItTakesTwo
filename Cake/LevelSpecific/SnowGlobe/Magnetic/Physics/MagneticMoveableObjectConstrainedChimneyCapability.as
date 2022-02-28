// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticMoveableComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticMoveableObjectConstrainedChimney;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.MagneticMoveableObjectConstrained;

// class UMagneticMoveableObjectConstrainedChimneyCapability : UHazeCapability
// {
// 	// Internal tick order for the TickGroup, Lowest ticks first.
// 	default TickGroupOrder = 1;
// 	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	
// 	UMagneticChimneyComponent MagnetMoveableComponent;
// 	AMagneticMoveableObjectConstrainedChimney CurrentObject;

// 	UPROPERTY()
// 	bool bShouldReverse;

// 	UPROPERTY()
// 	float MoveSpeed = 10;

// 	UPROPERTY()
// 	float RattleSize = 2;

// 	UPROPERTY()
// 	bool DontUsePlayerZOffset = false;

// 	FTransform StartTransform;
// 	float CurrentMovementProgress;
// 	float RattleTime = 0;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		CurrentObject = Cast<AMagneticMoveableObjectConstrainedChimney>(Owner);
// 		MagnetMoveableComponent = UMagneticChimneyComponent::Get(Owner);
// 		StartTransform = CurrentObject.Mesh.GetWorldTransform();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!IsActioning(n"UsingPhysicsObject"))
// 			return EHazeNetworkActivation::DontActivate;			

// 		return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(!IsActioning(n"UsingPhysicsObject"))
// 			return EHazeNetworkDeactivation::DeactivateFromControl;

// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

	
// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		RattleTime = 0;
// 		bShouldReverse = true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
// 		if (bShouldReverse)
// 		{
// 			if(CurrentMovementProgress == 0)
// 			{
// 				bShouldReverse = true;
// 				return;
// 			}
// 			CurrentMovementProgress = FMath::LerpStable(CurrentMovementProgress, 0.f, DeltaTime * 2);

// 			if(!IsActive())
// 			{
// 				UpdateMeshLocation();
// 			}
// 		}

// 	}
	
// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if (RattleTime < 0.65f)
// 		{
// 			RattleTime += DeltaTime;
// 			UpdateRattleState(DeltaTime);
// 			RattleTime = FMath::Clamp(RattleTime, 0.f, 0.65f);
// 		}
// 		else
// 		{
// 			if (PullValue != 0)
// 			{
// 				CurrentMovementProgress += GetPullValue() * DeltaTime * MoveSpeed;
// 			}
// 		}
// 		CurrentMovementProgress = FMath::Clamp(CurrentMovementProgress, -1.f, 1.f);

// 		UpdateMeshLocation();
// 	}

// 	void UpdateRattleState(float DeltaTime)
// 	{
// 		CurrentMovementProgress += FMath::Sin(RattleTime * 120) * DeltaTime * RattleSize;
// 	}

// 	float GetPullValue()
// 	{
// 		if (MagnetMoveableComponent.PlayersInfluencingObject.Num() > 0)
// 		{	
// 			FVector ResultingDirToInfluencers;
// 			FVector MagneticComponentLocation = UMagneticComponent::Get(Owner).WorldLocation;

// 			for (AHazePlayerCharacter Player : MagnetMoveableComponent.PlayersInfluencingObject)
// 			{
// 				UMagneticPlayerComponent PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);;
				
// 				EMagnetPolarity Polarity = MagnetMoveableComponent.Polarity;

// 				if(Polarity == EMagnetPolarity::Plus_Red)
// 				{
// 					if (PlayerMagnetComp.Polarity == EMagnetPolarity::Plus_Red)
// 					{
// 						ResultingDirToInfluencers += MagneticComponentLocation - Player.ActorLocation;
// 					}

// 					else if (PlayerMagnetComp.Polarity == EMagnetPolarity::Minus_Blue)
// 					{
// 						ResultingDirToInfluencers += Player.ActorLocation - MagneticComponentLocation;	
// 					}
// 				}

// 				else if (Polarity == EMagnetPolarity::Minus_Blue)
// 				{
// 					if (PlayerMagnetComp.Polarity == EMagnetPolarity::Plus_Red)
// 					{
// 						ResultingDirToInfluencers += Player.ActorLocation - MagneticComponentLocation;	
// 					}

// 					else if (PlayerMagnetComp.Polarity == EMagnetPolarity::Minus_Blue)
// 					{
// 						ResultingDirToInfluencers += MagneticComponentLocation - Player.ActorLocation;	
// 					}
// 				}
// 			}
// 			if (DontUsePlayerZOffset)
// 			{
// 				ResultingDirToInfluencers.Z = 0;
// 			}
			
// 			ResultingDirToInfluencers = ResultingDirToInfluencers / MagnetMoveableComponent.PlayersInfluencingObject.Num();
// 			ResultingDirToInfluencers.Normalize();

// 			float DotToForward = ResultingDirToInfluencers.DotProduct(CurrentObject.ForwardArrow.ForwardVector);
// 			return DotToForward;
// 		}

// 		return 0;
// 	}

// 	void UpdateMeshLocation()
// 	{
// 		FTransform Transform = StartTransform;

// 		if (CurrentMovementProgress < 0)
// 		{
// 			Transform.Blend(StartTransform, CurrentObject.PushLocation.GetWorldTransform(), FMath::Abs(CurrentMovementProgress));
// 		}

// 		if(CurrentMovementProgress > 0)
// 		{
// 			Transform.Blend(StartTransform, CurrentObject.PullLocation.GetWorldTransform(), CurrentMovementProgress);
// 		}
		
// 		CurrentObject.Mesh.SetWorldTransform(Transform);

// 		if(CurrentMovementProgress == -1 && !CurrentObject.bReachedEnd)
// 		{
// 			CurrentObject.OnLidIsOpenStateChanged.Broadcast(true, CurrentObject);
// 			CurrentObject.bReachedEnd = true;
// 		}

// 		else if (CurrentMovementProgress > -1 && CurrentObject.bReachedEnd)
// 		{
// 			CurrentObject.OnLidIsOpenStateChanged.Broadcast(false, CurrentObject);
// 			CurrentObject.bReachedEnd = false;
// 		}
// 	}

// }