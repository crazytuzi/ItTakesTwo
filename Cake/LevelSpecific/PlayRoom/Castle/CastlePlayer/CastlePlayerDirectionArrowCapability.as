import Vino.Movement.Components.MovementComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class UCastlePlayerDirectionArrowCapability : UHazeCapability
{
    default CapabilityTags.Add(n"CastlePlayerArrow");
    default CapabilityTags.Add(n"PlayerArrow");
    default CapabilityTags.Add(n"Visibility");

    UPROPERTY()
    TSubclassOf<ADecalActor> Decal;

	UPROPERTY()
    FLinearColor DecalColor = FLinearColor(1.0, 1.0, 1.0, 1.0);

    AActor DecalActor;

    UHazeMovementComponent Movement;
	AHazePlayerCharacter OwningPlayer;

    UMaterialInstanceDynamic DecalMaterial;



    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		PlaceDecalAtOwnersFeet();
        //PlaceDecalOnGround();
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsPlayerDead(OwningPlayer))
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsPlayerDead(OwningPlayer))
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);		
		Movement = UHazeMovementComponent::GetOrCreate(Owner);

        DecalActor = SpawnPersistentActor(Decal, OwningPlayer.ActorLocation, OwningPlayer.ActorRotation);
        DecalMaterial = Cast<ADecalActor>(DecalActor).Decal.CreateDynamicMaterialInstance();

        DecalMaterial.SetVectorParameterValue(FName("BaseColor"), DecalColor);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (DecalActor != nullptr)
			DecalActor.DestroyActor();
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
       // Player.Mesh.CastShadow = false;
        DecalActor.SetActorHiddenInGame(false);
	}
    
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
       // Player.Mesh.CastShadow = true;
        DecalActor.SetActorHiddenInGame(true);
	}

	void PlaceDecalAtOwnersFeet()
	{
		DecalActor.SetActorLocation(OwningPlayer.ActorLocation);
		DecalActor.SetActorRotation(OwningPlayer.ActorRotation + FRotator(270,0,0));
		DecalActor.SetActorRelativeScale3D(FVector(0.60, 0.60, 0.60));
	}


    void PlaceDecalOnGround()
    {
        FVector TraceEndLoc = OwningPlayer.ActorLocation - Movement.WorldUp * 8000.f;
        FVector TraceStartLoc = OwningPlayer.ActorLocation;
        TArray<AActor> ActorsToIgnore;
        ActorsToIgnore.Add(Game::GetMay());
        ActorsToIgnore.Add(Game::GetCody());
        FHitResult HitResult;
        System::SphereTraceSingle(TraceStartLoc, TraceEndLoc, 30, ETraceTypeQuery::TraceTypeQuery1, false, ActorsToIgnore, EDrawDebugTrace::None, HitResult, true);
        
        float DistanceToGround = HitResult.Distance;      

        if (HitResult.bBlockingHit == true)
        {
            DecalActor.SetActorLocation(HitResult.ImpactPoint);
            DecalActor.SetActorRotation(OwningPlayer.ActorRotation + FRotator(270,0,0));
            DecalActor.SetActorRelativeScale3D(FVector(0.60, 0.60, 0.60));
        }
    }
}
