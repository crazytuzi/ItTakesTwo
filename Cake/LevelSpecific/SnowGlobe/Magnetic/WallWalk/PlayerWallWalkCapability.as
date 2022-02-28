
// import Vino.Movement.Components.MovementComponent;

// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

// class PlayerWallWalkCapability : UHazeCapability
// {
// 	AHazePlayerCharacter Player;
// 	UHazePlayerPointActivationComponent PlayerFindMagnetComp;
// 	UMagneticPlayerComponent MagnetComponent;
// 	UHazeMovementComponent MoveComp;
// 	FHazeAcceleratedRotator Rotator;
	

// 	FVector UpNormal;

// 	default TickGroup = ECapabilityTickGroups::GamePlay;
// 	default TickGroupOrder = 110;
// 	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		PlayerFindMagnetComp = UHazePlayerPointActivationComponent::Get(Player);
// 		MoveComp = UHazeMovementComponent::Get(Player);
// 		MagnetComponent = UMagneticPlayerComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		// if(Container.UsedComp != nullptr)
// 		// {
// 		// 	//Too hard to implement!
// 		// 	//if(MagnetComponent.IsInfluencedBy(Player.OtherPlayer))
// 		// 	//{
// 		// 		if(Container.UsedComp.Owner == Player.OtherPlayer)
// 		// 		{
// 		// 			if (MoveComp.ForwardHit.Component != nullptr)
// 		// 			{
// 		// 				if(MoveComp.GetForwardHit().Component.HasTag(n"WallWalkable"))
// 		// 				{
// 		// 					return EHazeNetworkActivation::ActivateFromControl;
// 		// 				}
// 		// 			}
// 		// 		}
// 		// 	//}
// 		// }

// 		return EHazeNetworkActivation::DontActivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		if(MoveComp.GetForwardHit().Component.HasTag(n"WallWalkable"))
// 		{
// 			Owner.BlockCapabilities(FMagneticTags::PlayerBeingAttracted, this);
// 			Rotator.SnapTo(Player.GetActorUpVector().Rotation());
// 			UpNormal = MoveComp.GetForwardHit().Normal;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		Owner.UnblockCapabilities(FMagneticTags::PlayerBeingAttracted, this);
// 		Player.ChangeActorWorldUp(FVector::UpVector);
// 		UMovementSettings::ClearMoveSpeed(Player, this);
// 	}

// 	float GetDistanceToOtherPlayer() const
// 	{
// 		return Player.ActorLocation.Distance(Player.OtherPlayer.ActorLocation);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		// if(Container.UsedComp == nullptr)
// 		// {
// 		// 	return EHazeNetworkDeactivation::DeactivateFromControl;
// 		// }

// 		// else
// 		{
//         	return EHazeNetworkDeactivation::DontDeactivate;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		Rotator.AccelerateTo(UpNormal.Rotation(), 1, DeltaTime);
//         Player.ChangeActorWorldUp(Rotator.Value.Vector());

// 		UMovementSettings::SetMoveSpeed(Player, MoveSpeed, this);
// 		//MoveComp.speed

// 		//UHazeActiveCameraUserComponent::Get(Player).SetYawAxis(FVector::UpVector);
// 		//Player.ChangeActorWorldUp(UpNormal);
// 	}

// 	float GetMoveSpeed()
// 	{
// 		float MoveSpeedToReturn;

// 		float PercentageDistance = DistanceToOtherPlayer / 300;
// 		PercentageDistance = 1-  PercentageDistance;
		
// 		FVector MoveDirection = MoveComp.Velocity.GetSafeNormal();
// 		FVector DirToOtherPlayer = (Player.OtherPlayer.ActorLocation - Player.ActorLocation).GetSafeNormal();
// 		float Dot = MoveDirection.DotProduct(DirToOtherPlayer);

// 		Dot = (Dot + 1 ) * 0.5f;
// 		Dot = 1 - Dot;
// 		MoveSpeedToReturn = FMath::Lerp(MoveComp.DefaultMovementSpeed, MoveComp.DefaultMovementSpeed * PercentageDistance, Dot);

// 		return MoveSpeedToReturn;
// 	}
// }