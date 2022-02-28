import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.HeliumPackage.HeliumPackage;
import Vino.Pickups.PlayerPickupComponent;

class UHeliumPackageMovementCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"HeliumPackage";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UMeshComponent MeshComponent;
	AHeliumPackage Package;
	UMagnetPickupComponent MagneticComp;

	FVector Velocity;
	float CurrentSpeed = 0.0f;

	float FlyingTime = 0.0f;

	float VerticalMoveSpeed = 250.0f;
	float PlayerMoveSpeed = 150.0f;
	float HorizontalMoveSpeed = 50.0f;

	bool bPlayersOnPackage = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Package = Cast<AHeliumPackage>(Owner);
		MeshComponent = UMeshComponent::Get(Owner);
        MagneticComp = UMagnetPickupComponent::Get(Owner);
		Package.PlayerOverlapCollider.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnteredOverlap");
		Package.PlayerOverlapCollider.OnComponentEndOverlap.AddUFunction(this, n"PlayerLeftOverlap");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;

		// if(MagneticComp.GetInfluencerNum() > 0 || Package.IsPickedUp())
       	// 	return EHazeNetworkActivation::DontActivate;
			   
       	// return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticComp.GetInfluencerNum() > 0 || Package.IsPickedUp())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(MeshComponent.IsGravityEnabled())
		{
       		MeshComponent.SetEnableGravity(false);
		}

		if(MeshComponent.IsSimulatingPhysics())
		{
			MeshComponent.SetSimulatePhysics(false);
		}

		Package.SetCurrentState(EHeliumPackageState::Free);
		Package.PlayerCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Package.PlayerOverlapCollider.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Package.PlayerCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Package.PlayerOverlapCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		FlyingTime = 0.0f;
		Velocity = 0.0f;
		bPlayersOnPackage = false;
		CurrentSpeed = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeAcceleratedRotator AcceleratedRot;
		AcceleratedRot.Value = MeshComponent.WorldRotation;

    	FlyingTime+=DeltaTime;

		float NewVerticalMoveSpeed = VerticalMoveSpeed;

		if(Package.OverlappingPlayers.Num() > 1)
		{
			NewVerticalMoveSpeed = -NewVerticalMoveSpeed;
			bPlayersOnPackage = true;
		}
		else if(Package.OverlappingPlayers.Num() > 0)
		{
			NewVerticalMoveSpeed = PlayerMoveSpeed;

			if(CurrentSpeed < PlayerMoveSpeed)
			{
				FHazeAcceleratedFloat AcceleratedSpeed;
				AcceleratedSpeed.Value = CurrentSpeed;
				AcceleratedSpeed.AccelerateTo(NewVerticalMoveSpeed, 0.5f, DeltaTime);
				NewVerticalMoveSpeed = AcceleratedSpeed.Value;
			}

			bPlayersOnPackage = true;
		}
		else
		{
			bPlayersOnPackage = false;
			FHazeAcceleratedFloat AcceleratedSpeed;
			AcceleratedSpeed.Value = CurrentSpeed;
			AcceleratedSpeed.AccelerateTo(NewVerticalMoveSpeed, 0.5f, DeltaTime);
			NewVerticalMoveSpeed = AcceleratedSpeed.Value;
		}

		Velocity = FVector::UpVector * NewVerticalMoveSpeed * DeltaTime;
		CurrentSpeed = NewVerticalMoveSpeed;
		//Velocity += Package.ActorRightVector * FMath::Sin(FlyingTime * 1.5f) * HorizontalMoveSpeed * DeltaTime;
		//Print("" + CurrentSpeed);

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());
		FHitResult Hit;
		FVector StartLocation = Package.ActorLocation + Package.Collider.RelativeLocation;

		System::BoxTraceSingle(StartLocation, StartLocation + Velocity, Package.Collider.BoxExtent.Z, Package.ActorRotation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);
		
		if(Hit.bBlockingHit)
			Velocity = 0.0f;

		Package.AddActorWorldOffset(Velocity);
	}

	UFUNCTION()
	void PlayerEnteredOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		Package.OverlappingPlayers.Add(Player);
	}

	UFUNCTION()
    void PlayerLeftOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		Package.OverlappingPlayers.Remove(Player);
    }
}

