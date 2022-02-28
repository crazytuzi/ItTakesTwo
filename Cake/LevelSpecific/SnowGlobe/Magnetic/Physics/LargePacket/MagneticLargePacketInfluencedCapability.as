
// import Vino.Movement.Components.MovementComponent;
// import Vino.Movement.MovementSystemTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Physics.LargePacket.MagneticLargePacket;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPhysicalComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

// class UMagneticLargePacketInfluencedCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(MovementSystemTags::AirMovement);
// 	default CapabilityTags.Add(FMagneticTags::LiftedUpInAir);
	
// 	default TickGroup = ECapabilityTickGroups::ReactionMovement;

// 	default CapabilityDebugCategory = CapabilityTags::Movement;

// 	UHazePhysicalMovementComponent MovementComponent;
// 	AMagneticLargePacket PacketOwner;
// 	UMagneticPhysicalComponent LeftMagnetComponent;
// 	UMagneticPhysicalComponent RightMagnetComponent;
// 	float OriginalGravityAmount = 0;
	
// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		PacketOwner = Cast<AMagneticLargePacket>(Owner);
//      	MovementComponent = UHazePhysicalMovementComponent::Get(Owner);
// 		LeftMagnetComponent = PacketOwner.LeftMagnet;
// 		RightMagnetComponent = PacketOwner.RightMagnet;
// 		OriginalGravityAmount = MovementComponent.GravityScale;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void PreTick(float DeltaTime)
// 	{
		
// 	}

// 	bool ShouldBeActive()const
// 	{
// 		if(PacketOwner.GetInfluencingPlayerCount() < 1)
// 			return false;

// 		if(PacketOwner.bIsHeavy)
// 			return false;

// 		return true;
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(!ShouldBeActive())
// 			return EHazeNetworkActivation::DontActivate;

// 		return EHazeNetworkActivation::ActivateLocal;	
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(!ShouldBeActive())
// 			return EHazeNetworkDeactivation::DeactivateLocal;

//         return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
	
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		PacketOwner.ClearPivotLocation();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		FMagnetInfluencer LeftInfluencer;
// 		const bool bAffectedLeft = PacketOwner.ExtractMagnetParamsFromInfluence(LeftMagnetComponent, LeftInfluencer);

// 		FMagnetInfluencer RightInfluencer;
// 		const bool bAffectedRight = PacketOwner.ExtractMagnetParamsFromInfluence(RightMagnetComponent, RightInfluencer);

// 		if(bAffectedLeft && bAffectedRight)
// 		{
// 			AHazePlayerCharacter LeftPlayer = Cast<AHazePlayerCharacter>(LeftInfluencer.Instigator);
// 			const FTransform LeftMagnetTransform = LeftMagnetComponent.GetTransformFor(LeftPlayer);

// 			AHazePlayerCharacter RightPlayer = Cast<AHazePlayerCharacter>(RightInfluencer.Instigator);
// 			const FTransform RightMagnetTransform = RightMagnetComponent.GetTransformFor(RightPlayer);

// 			FVector PivotLocation = (LeftMagnetTransform.Location + RightMagnetTransform.Location) * 0.5f;
			
// 			// Left is closer the right
// 			if(LeftInfluencer.DistanceAlpha < RightInfluencer.DistanceAlpha)
// 			{
// 				const float DistAlpha = (1 - LeftInfluencer.DistanceAlpha) - (1 - RightInfluencer.DistanceAlpha);
// 				// On the left we rotate around the right
// 				PivotLocation = FMath::Lerp(PivotLocation, RightMagnetTransform.Location, DistAlpha);
// 			}
// 			else
// 			{
// 				const float DistAlpha = (1 - RightInfluencer.DistanceAlpha) - (1 - LeftInfluencer.DistanceAlpha);
// 				// On the right we rotate around the left
// 				PivotLocation = FMath::Lerp(PivotLocation, LeftMagnetTransform.Location, DistAlpha);
// 			}
// 			PacketOwner.SetPivotLocation(PivotLocation);
// 		}
// 		else if(bAffectedLeft)
// 		{
// 			AHazePlayerCharacter LeftPlayer = Cast<AHazePlayerCharacter>(LeftInfluencer.Instigator);
// 			const FTransform RightMagnetTransform = RightMagnetComponent.GetTransformFor(LeftPlayer);
			
// 			// On the left we rotate around the right
// 			FVector PivotLocation = RightMagnetTransform.Location;
// 			PacketOwner.SetPivotLocation(PivotLocation);
// 		}
// 		else if(bAffectedRight)
// 		{
// 			AHazePlayerCharacter RightPlayer = Cast<AHazePlayerCharacter>(LeftInfluencer.Instigator);
// 			const FTransform LeftMagnetTransform = LeftMagnetComponent.GetTransformFor(RightPlayer);
	
// 			// On the right we rotate around the left
// 			FVector PivotLocation = LeftMagnetTransform.Location;
// 			PacketOwner.SetPivotLocation(PivotLocation);
// 		}

// 		if(bAffectedLeft && bAffectedRight)
// 		{
// 			ApplyInfluenceOnMagnetComponents(DeltaTime, LeftInfluencer, RightInfluencer);
// 		}
// 		else
// 		{
// 			PacketOwner.BeginSimulation();
// 			MovementComponent.GravityScale = OriginalGravityAmount;
// 			if(bAffectedLeft)
// 			{
// 				ApplyInfluenceOnMagnetComponent(DeltaTime, LeftMagnetComponent, LeftInfluencer);
// 			}
// 			if(bAffectedRight)
// 			{
// 				ApplyInfluenceOnMagnetComponent(DeltaTime, RightMagnetComponent, RightInfluencer);
// 			}
// 		}
// 	}

// 	void ApplyInfluenceOnMagnetComponent(float DeltaTime, UMagneticPhysicalComponent Magnet, const FMagnetInfluencer& Influencer)
// 	{
// 		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Influencer.Instigator);
// 		UMagneticPlayerComponent PlayerMagnet = UMagneticPlayerComponent::Get(Player);
			
//  		const FTransform MagnetTransform = Magnet.GetTransformFor(Player);
// 		const FVector DirToMagnet = (MagnetTransform.Location - Player.GetActorCenterLocation()).ConstrainToPlane(PacketOwner.GetActorUpVector()).GetSafeNormal();
// 		const FVector MagnetRight = PacketOwner.GetActorRightVector();
// 		const FVector MagnetForward = PacketOwner.GetActorForwardVector();
// 		const float RightDot = DirToMagnet.DotProduct(MagnetRight);
// 		const float ForwardDot = DirToMagnet.DotProduct(MagnetForward);

// 		const bool bIsGrounded = IsGrounded(MagnetTransform);
// 		const float MoveSpeed = bIsGrounded ? PacketOwner.GroundedMovespeed : PacketOwner.InAirMovespeed;
// 		const float RotationSpeed = bIsGrounded ? PacketOwner.GroundedRotationMaxAmount : PacketOwner.InAirRotationMaxAmount;
// 		const float ForceAmount = Influencer.NegativeForce - Influencer.PositiveForce;

// 		if(FMath::Abs(ForceAmount) > 0.f)
// 		{
// 			const bool bIsRightMagnet = Magnet == PacketOwner.RightMagnet;
// 			const FVector CurrentDir = bIsRightMagnet ? MagnetRight : -MagnetRight;
// 			const FVector TargetDir = (-DirToMagnet);
// 			FRotator TargetRotation = Math::RotateVectorTowards(CurrentDir, TargetDir, FMath::Abs(ForceAmount) * RotationSpeed * DeltaTime).ToOrientationRotator();
// 			if(bIsRightMagnet)
// 				TargetRotation.Yaw -= 90.f;
// 			else
// 				TargetRotation.Yaw += 90.f;

// 			const FRotator DeltaRotation = (TargetRotation - PacketOwner.GetActorRotation()).GetNormalized();
// 			RotateAroundPivot(DeltaRotation.Yaw);
// 		}
// 	}

// 	void ApplyInfluenceOnMagnetComponents(float DeltaTime, const FMagnetInfluencer& Leftfluencer, const FMagnetInfluencer& Rightfluencer)
// 	{
// 		// Actor
// 		const FVector MagnetRight = PacketOwner.GetActorRightVector();
// 		const FVector MagnetForward = PacketOwner.GetActorForwardVector();

// 		// Left
// 		AHazePlayerCharacter LeftPlayer = Cast<AHazePlayerCharacter>(Leftfluencer.Instigator);
// 		UMagneticPlayerComponent LeftPlayerMagnet = UMagneticPlayerComponent::Get(LeftPlayer);
		
// 		const FTransform LeftMagnetTransform = LeftMagnetComponent.GetTransformFor(LeftPlayer);
// 		const FVector DirToLeftMagnet = (LeftMagnetTransform.Location - LeftPlayer.GetActorCenterLocation()).ConstrainToPlane(PacketOwner.GetActorUpVector()).GetSafeNormal();

// 		const float LeftRightDot = DirToLeftMagnet.DotProduct(MagnetRight);
// 		const float LeftForwardDot = DirToLeftMagnet.DotProduct(MagnetForward);
// 		const float LeftInput = Leftfluencer.GetInputAlpha();
// 		FVector LeftPlayerLocation = LeftPlayer.GetActorCenterLocation();

// 		// Right
// 		AHazePlayerCharacter RightPlayer = Cast<AHazePlayerCharacter>(Rightfluencer.Instigator);
// 		UMagneticPlayerComponent RightPlayerMagnet = UMagneticPlayerComponent::Get(RightPlayer);
		
// 		const FTransform RightMagnetTransform = RightMagnetComponent.GetTransformFor(RightPlayer);
// 		const FVector DirToRightMagnet = (RightMagnetTransform.Location - RightPlayer.GetActorCenterLocation()).ConstrainToPlane(PacketOwner.GetActorUpVector()).GetSafeNormal();

// 		const float RightRightDot = DirToRightMagnet.DotProduct(MagnetRight);
// 		const float RightForwardDot = DirToRightMagnet.DotProduct(MagnetForward);
// 		const float RightInput = Leftfluencer.GetInputAlpha();
// 		FVector RightPlayerLocation = RightPlayer.GetActorCenterLocation();
		
// 		// Total
// 		const float TotalInputAmount = (LeftInput + RightInput) * 0.5f;
// 		LeftPlayerLocation += PacketOwner.GetActorUpVector() * (LeftPlayer.GetCollisionSize().Y * 0.5f);
// 		RightPlayerLocation += PacketOwner.GetActorUpVector() * (RightPlayer.GetCollisionSize().Y * 0.5f);

// 		// Update Rotation
// 		if(TotalInputAmount > 0.f)
// 		{
// 			PacketOwner.BeginSimulation();
// 			MovementComponent.GravityScale = 0;

// 			const FVector CurrentDir = MagnetRight;
// 			const FVector TargetDir = (RightPlayerLocation - LeftPlayerLocation).ConstrainToPlane(PacketOwner.GetActorUpVector()).GetSafeNormal();
// 			FRotator TargetRotation = Math::RotateVectorTowards(CurrentDir, TargetDir, TotalInputAmount * PacketOwner.InAirRotationMaxAmount * DeltaTime).ToOrientationRotator();
// 			TargetRotation.Yaw -= 90.f;

// 			const FRotator DeltaRotation = (TargetRotation - PacketOwner.GetActorRotation()).GetNormalized();
// 			RotateAroundPivot(DeltaRotation.Yaw);

// 			const FVector MiddlePosition = (LeftPlayerLocation + RightPlayerLocation) * 0.5f;

// 			const FVector LeftMaxPosition = LeftPlayerLocation + (DirToLeftMagnet * (PacketOwner.CollisionRootComponent.BoxExtent.Y + LeftPlayer.GetCollisionSize().X + 10));
// 			const FVector RightMaxPosition = RightPlayerLocation + (DirToRightMagnet * (PacketOwner.CollisionRootComponent.BoxExtent.Y + RightPlayer.GetCollisionSize().X + 10));
			
// 			FVector TargetLocation = MiddlePosition;
// 			if(LeftInput > RightInput)
// 			{
// 				const float LeftAlpha = RightInput / LeftInput;
// 				TargetLocation = FMath::Lerp(MiddlePosition, LeftMaxPosition, 1 - LeftAlpha);
// 			}
// 			else if(LeftInput < RightInput)
// 			{
// 				const float RightAlpha = LeftInput / RightInput;
// 				TargetLocation = FMath::Lerp(MiddlePosition, RightMaxPosition,  1 - RightAlpha);
// 			}

// 			FVector DeltaMovement = FMath::VInterpConstantTo(PacketOwner.GetActorLocation(), TargetLocation, DeltaTime, PacketOwner.InAirMovespeed * TotalInputAmount);
// 			PacketOwner.MovementComponent.MoveInterpolationTarget(DeltaMovement, PacketOwner.GetActorRotation());	
// 		}
// 		else
// 		{
// 			PacketOwner.BeginSimulation();
// 			MovementComponent.GravityScale = OriginalGravityAmount;
// 		}
// 	}

// 	void RotateAroundPivot(const float NewRotationAmount)
// 	{
// 		const FTransform LastWorldTransform = PacketOwner.GetActorTransform();
// 		const FVector WorldPivotLocation = PacketOwner.GetWorldPivotLocation();
// 		const FVector DeltaTranslation = WorldPivotLocation - LastWorldTransform.Location;

// 		FRotator NewRotation = FRotator(0.f, NewRotationAmount, 0.f);
// 		PacketOwner.SetActorLocation(WorldPivotLocation);
// 		PacketOwner.SetActorRotation(PacketOwner.GetActorRotation() + NewRotation);
// 		const FVector InversTranslation = NewRotation.RotateVector(-DeltaTranslation);
// 		const FTransform NewWorldTransform = PacketOwner.GetActorTransform();
// 		PacketOwner.SetActorLocation(NewWorldTransform.Location + InversTranslation);
// 	}

// 	bool IsGrounded(const FTransform AtTransform)
// 	{
// 		TArray<AActor> IgnoreActors;
// 		FName CollisionProfileName = PacketOwner.CollisionRootComponent.GetCollisionProfileName();
// 		FHitResult GroundHitResult;
// 		const bool bHitSomething = System::LineTraceSingleByProfile(
// 			AtTransform.Location, 
// 			AtTransform.Location - (PacketOwner.GetActorUpVector() * PacketOwner.CollisionRootComponent.BoxExtent.Z + 10),
// 			CollisionProfileName,
// 			false, 
// 			IgnoreActors,
// 			EDrawDebugTrace::None,
// 			GroundHitResult,
// 			true);

// 		return bHitSomething;
// 	}
// }