import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class UParentBlobPlayerInputIndicatorCapability : UHazeCapability
{    
    UPROPERTY()
    TSubclassOf<ADecalActor> Decal;

	UPROPERTY()
    FLinearColor MayDecalColor = FLinearColor(1.0, 1.0, 1.0, 1.0);
	UPROPERTY()
    FLinearColor CodyDecalColor = FLinearColor(1.0, 1.0, 1.0, 1.0);


	TPerPlayer<ADecalActor> DecalActors;
	TPerPlayer<UMaterialInstanceDynamic> DecalMaterials;

    UHazeMovementComponent Movement;
	AParentBlob ParentBlob;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			DecalActors[Player] = Cast<ADecalActor>(SpawnPersistentActor(Decal, ParentBlob.ActorLocation, ParentBlob.ActorRotation));

			DecalMaterials[Player] = DecalActors[Player].Decal.CreateDynamicMaterialInstance();
			
			if (Player.IsMay())
				DecalMaterials[Player].SetVectorParameterValue(FName("Emissive"), Player.DebugColor * 0.5f);
			else
				DecalMaterials[Player].SetVectorParameterValue(FName("Emissive"), Player.DebugColor * 0.5f);

			DecalActors[Player].SetActorHiddenInGame(true);
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (DecalActors[Player] != nullptr)
				DecalActors[Player].DestroyActor();
		}
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;
        // return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
           return EHazeNetworkDeactivation::DontDeactivate;
	}


    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			DecalActors[Player].SetActorHiddenInGame(false);
		}
	}
    
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			DecalActors[Player].SetActorHiddenInGame(true);
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			SetVisibilityBasedOnInput(Player);
			PlaceDecalAtOwnersFeet(Player);
		}
    }
	void PlaceDecalAtOwnersFeet(AHazePlayerCharacter Player)
	{
			float OffsetScalar = Player.IsCody() ? 1.f : -1.f;
			FVector PlayerOffset = ParentBlob.ActorRightVector * 0.f * OffsetScalar;

			DecalActors[Player].SetActorLocation(ParentBlob.ActorLocation + PlayerOffset);
			DecalActors[Player].SetActorRotation(Math::MakeRotFromX(ParentBlob.PlayerMovementDirection[Player]) + FRotator(270,0,0));
	}  
	void SetVisibilityBasedOnInput(AHazePlayerCharacter Player)
	{
		if (ParentBlob.PlayerMovementDirection[Player].Size() < 0.01)
		{
			DecalActors[Player].SetActorHiddenInGame(true);
		}
		else
			DecalActors[Player].SetActorHiddenInGame(false);

	}  
}
