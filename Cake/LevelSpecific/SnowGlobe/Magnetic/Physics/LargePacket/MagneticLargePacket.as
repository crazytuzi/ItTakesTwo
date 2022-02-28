
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticMoveableComponent;
// import Vino.Movement.Components.MovementComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPhysicalComponent;

// UCLASS(hidecategories="Lighting Rendering Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
// class AMagneticLargePacket : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	UBoxComponent CollisionRootComponent;
// 	default CollisionRootComponent.BoxExtent = FVector(1.f, 1.f, 1.f);
// 	default CollisionRootComponent.SetSimulatePhysics(false);

// 	UPROPERTY(DefaultComponent, Attach = CollisionRootComponent)
// 	USceneComponent RotationComponent;

// 	UPROPERTY(DefaultComponent, Attach = RotationComponent)
// 	UStaticMeshComponent MeshComponent;
// 	default MeshComponent.SetSimulatePhysics(false);

// 	UPROPERTY(DefaultComponent, Attach = RotationComponent)
// 	UMagneticPhysicalComponent LeftMagnet;
// 	default LeftMagnet.Polarity = EMagnetPolarity::Plus_Red;
// 	default LeftMagnet.DistanceValidationBonusScore = 200.f;

// 	UPROPERTY(DefaultComponent, Attach = LeftMagnet)
// 	UStaticMeshComponent LeftMeshComponent;
// 	default LeftMeshComponent.SetSimulatePhysics(false);


// 	UPROPERTY(DefaultComponent, Attach = RotationComponent)
// 	UMagneticPhysicalComponent RightMagnet;
// 	default RightMagnet.Polarity = EMagnetPolarity::Minus_Blue;
// 	default RightMagnet.DistanceValidationBonusScore = 200.f;

// 	UPROPERTY(DefaultComponent, Attach = RightMagnet)
// 	UStaticMeshComponent RightMeshComponent;
// 	default RightMeshComponent.SetSimulatePhysics(false);

// 	UPROPERTY(DefaultComponent)
// 	UHazePhysicalMovementComponent MovementComponent;
// 	default MovementComponent.bShouldBounce = true;
// 	default MovementComponent.bSimulationEnabled = true;
// 	default MovementComponent.GravityScale = 3.f;
// 	default MovementComponent.Bounciness = 0.3f;

// 	UPROPERTY(EditDefaultsOnly)
// 	UMaterialInterface RedMaterial;

// 	UPROPERTY(EditDefaultsOnly)
// 	UMaterialInterface BlueMaterial;

// 	UPROPERTY(EditDefaultsOnly)
// 	float GravityMultiplier = 3;

// 	UPROPERTY(EditDefaultsOnly)
// 	float VisibleDistance = 3200;

// 	UPROPERTY(EditDefaultsOnly)
// 	float TargetableDistance = 1600;

// 	UPROPERTY(EditDefaultsOnly)
// 	float SelectableDistance = 800;

// 	UPROPERTY(EditDefaultsOnly)
// 	float GroundedMovespeed = 0.f;

// 	UPROPERTY(EditDefaultsOnly)
// 	float InAirMovespeed = 400.f;

// 	UPROPERTY(EditDefaultsOnly)
// 	float GroundedRotationMaxAmount = 20.f;

// 	UPROPERTY(EditDefaultsOnly)
// 	float InAirRotationMaxAmount = 80.f;

// 	UPROPERTY()
// 	bool bIsHeavy = false;

// 	FVector LeftMagnetForce;
// 	FVector RightMagnetForce;

// 	FVector LocalPivot = FVector::ZeroVector;
// 	FVector LocalTargetPivot = FVector::ZeroVector;

// 	UFUNCTION(BlueprintOverride)
// 	void ConstructionScript()
// 	{
// 		if (LeftMagnet.Polarity == EMagnetPolarity::Plus_Red)
// 		{
// 			LeftMeshComponent.SetMaterial(0, RedMaterial);
// 		}
// 		else
// 		{
// 			LeftMeshComponent.SetMaterial(0, BlueMaterial);
// 		}
	
// 		LeftMagnet.InitializeDistance(EHazeActivationPointDistanceType::Visible, VisibleDistance);
// 		LeftMagnet.InitializeDistance(EHazeActivationPointDistanceType::Targetable, TargetableDistance);
// 		LeftMagnet.InitializeDistance(EHazeActivationPointDistanceType::Selectable, SelectableDistance);


// 		if (RightMagnet.Polarity == EMagnetPolarity::Plus_Red)
// 		{
// 			RightMeshComponent.SetMaterial(0, RedMaterial);
// 		}
// 		else
// 		{
// 			RightMeshComponent.SetMaterial(0, BlueMaterial);
// 		}

// 		RightMagnet.InitializeDistance(EHazeActivationPointDistanceType::Visible, VisibleDistance);
// 		RightMagnet.InitializeDistance(EHazeActivationPointDistanceType::Targetable, TargetableDistance);
// 		RightMagnet.InitializeDistance(EHazeActivationPointDistanceType::Selectable, SelectableDistance);		
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		AddCapability(n"MagneticLargePacketGroundMoveCapability");
// 		AddCapability(n"MagneticLargePacketInfluencedCapability");
// 		AddCapability(n"MagneticLargePacketInfluencedAttachedCapability");

// 		BeginSimulation();
// 	}

// 	void BeginSimulation()
// 	{
// 		MovementComponent.SetUpdatedComponent(CollisionRootComponent);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void Tick(float DeltaTime)
// 	{
// 		LocalPivot = FMath::VInterpConstantTo(LocalPivot, LocalTargetPivot, DeltaTime, LocalTargetPivot.Size() * 10.f);

// 		// System::DrawDebugArrow(GetActorLocation(), GetActorLocation() + (GetActorForwardVector() * 1000.f));
		
// 		// FTransform LeftTransform = LeftMagnet.GetTransformFor(Game::GetCody());
// 		// System::DrawDebugArrow(LeftTransform.Location, LeftTransform.Location + (LeftTransform.Rotation.GetForwardVector() * 1000.f));

// 		// FTransform RightTransform = RightMagnet.GetTransformFor(Game::GetCody());
// 		// System::DrawDebugArrow(RightTransform.Location, RightTransform.Location + (RightTransform.Rotation.GetForwardVector() * 1000.f));

// 		// const FTransform ParentTransform = GetActorTransform();
// 		// FVector WorlPivotLocation = ParentTransform.TransformPosition(LocalPivot);
// 		// System::DrawDebugSphere(WorlPivotLocation);
// 	}

// 	float GetTotalPositiveForce()const
// 	{
// 		return LeftMagnet.GetTotalPositiveForce() + RightMagnet.GetTotalPositiveForce();
// 	}

// 	float GetTotalNegativeForce()const
// 	{
// 		return LeftMagnet.GetTotalNegativeForce() + RightMagnet.GetTotalNegativeForce();
// 	}

// 	float GetResultingForce()const
// 	{
// 		return LeftMagnet.GetResultingForce() + RightMagnet.GetResultingForce();
// 	}

// 	int GetInfluencingPlayerCount()const
// 	{
// 		int Count = 0;
// 		// LEFT
// 		{
// 			TArray<AHazePlayerCharacter> Players;
// 			LeftMagnet.GetInfluencingPlayers(Players);
// 			Count += Players.Num();
// 		}

// 		// RIGHT
// 		{
// 			TArray<AHazePlayerCharacter> Players;
// 			RightMagnet.GetInfluencingPlayers(Players);
// 			Count += Players.Num();
// 		}

// 		return Count;
// 	}

// 	void SetPivotLocation(const FVector& Pivot)
// 	{
// 		const FTransform PivotWorldTransform(GetActorRotation(), Pivot);
// 	 	const FTransform ParentTransform = GetActorTransform();
// 	 	const FTransform PointRelativeTransform = PivotWorldTransform.GetRelativeTransform(ParentTransform);
// 		LocalTargetPivot = PointRelativeTransform.Location;
// 	}

// 	void ClearPivotLocation()
// 	{
// 		LocalTargetPivot = FVector::ZeroVector;
// 		LocalPivot = FVector::ZeroVector;
// 	}

// 	FVector GetWorldPivotLocation()const
// 	{
// 		const FTransform ParentTransform = GetActorTransform();
// 		return ParentTransform.TransformPosition(LocalPivot);
// 	}

// 	bool ExtractMagnetParamsFromInfluence(UMagneticPhysicalComponent Magnet, FMagnetInfluencer& OutInfluencer)
// 	{
// 		int PlayerCount = 0;
// 		int ArrayIndex = -1;
// 		TArray<FMagnetInfluencer> Influencers;
// 		Magnet.GetInfluencers(Influencers);
// 		for(int i = Influencers.Num() - 1; i >= 0; --i)
// 		{
// 			const FMagnetInfluencer& Influencer = Influencers[i];
// 			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Influencer.Instigator);
// 			if(Player == nullptr)
// 				continue;

// 			PlayerCount++;
// 			if(PlayerCount != 1)
// 				return false;

// 			ArrayIndex = i;
// 		}

// 		if(ArrayIndex < 0)
// 			return false;
		
// 		OutInfluencer = Influencers[ArrayIndex];
// 		return PlayerCount == 1 && OutInfluencer.GetDistanceAlpha() < 1.f && OutInfluencer.GetInputAlpha() > 0.f;
// 	}
// }