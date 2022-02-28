import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.HeliumPackage.HeliumPackage;
import Vino.Pickups.PlayerPickupComponent;

class UHeliumPackageTiltCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"HeliumPackage";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UMeshComponent MeshComponent;
	AHeliumPackage Package;
    UHazeBaseMovementComponent MoveComp;
	UMagnetPickupComponent MagneticComp;

	float MaxRotation = 15.0f;

	bool bStabilized = false;

	bool bPlayersOnPackage = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Package = Cast<AHeliumPackage>(Owner);
		MeshComponent = UMeshComponent::Get(Owner);
        MoveComp = UHazeBaseMovementComponent::Get(Owner);
        MagneticComp = UMagnetPickupComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Package.OverlappingPlayers.Num() <= 0)
       		return EHazeNetworkActivation::DontActivate;
			   
       	return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Package.OverlappingPlayers.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
       	return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayersOnPackage = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bPlayersOnPackage = false;
		bStabilized = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bStabilized && !bPlayersOnPackage)
		{
			float DeltaPitch = FMath::Lerp(Package.ActorRotation.Pitch, 0.0f, 7.5f * DeltaTime);
			float DeltaRoll = FMath::Lerp(Package.ActorRotation.Roll, 0.0f, 7.5f * DeltaTime);

			FRotator DeltaRotation = FRotator(DeltaPitch, Package.ActorRotation.Yaw, DeltaRoll);
			Package.SetActorRotation(DeltaRotation);
		}
		
		if(FMath::IsNearlyZero(Package.ActorRotation.Pitch, 0.001f) && FMath::IsNearlyZero(Package.ActorRotation.Roll, 0.001f))
			bStabilized = true;
		else
			bStabilized = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		TArray<FVector> RelativeLocations;
		FVector BoxAlpha;
		for(AHazePlayerCharacter Player : Package.OverlappingPlayers)
		{
			FVector RelativeLocation = Package.ActorTransform.InverseTransformPosition(Player.ActorLocation);
			RelativeLocations.Add(RelativeLocation);
			FVector Alpha = (RelativeLocation / Package.PlayerCollider.BoxExtent) * 0.5f;
			float AlphaX = FMath::Clamp(Alpha.X, -1.0f, 1.0f);
			float AlphaY = FMath::Clamp(Alpha.Y, -1.0f, 1.0f);
			BoxAlpha += FVector(AlphaX, AlphaY, 0.0f);
		}

		FRotator NewRotation = FRotator(-BoxAlpha.X * MaxRotation, 0.0f, BoxAlpha.Y * MaxRotation);

		float DeltaPitch = FMath::Lerp(Package.ActorRotation.Pitch, NewRotation.Pitch, 7.5f * DeltaTime);
		float DeltaRoll = FMath::Lerp(Package.ActorRotation.Roll, NewRotation.Roll, 7.5f * DeltaTime);

		FRotator DeltaRotation = FRotator(DeltaPitch, Package.ActorRotation.Yaw, DeltaRoll);
		Package.SetActorRotation(DeltaRotation);
	}
}
