import Vino.Movement.MovementSettings;
import Vino.Movement.MovementSystemTags;
import Vino.StickControlledLever.StickControlledLever;
import Cake.LevelSpecific.PlayRoom.SpaceStation.LowGravity.GravityVolumeObject;
import Vino.Movement.Jump.CharacterJumpSettings;
import Vino.Movement.Dash.CharacterDashSettings;

UCLASS(NotBlueprintable)
class ALowGravityVolume : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor::DPink);

	UPROPERTY()
	UMovementSettings LowGravityMovementSettings;

	UPROPERTY()
	UCharacterJumpSettings LowGravityJumpSettings;

	UPROPERTY()
	UCharacterAirDashSettings LowGravityAirDashSettings;

	UPROPERTY()
	bool bShowMesh = true;

	UPROPERTY()
	UStaticMesh MeshAsset = Asset("/Game/Environment/BasicShapes/Cube.Cube");

	UPROPERTY()
	UMaterialInstance Material = Asset("/Game/Effects/Materials/forcefiled_01.forcefiled_01");

	TArray<AHazePlayerCharacter> PlayersInVolume;

	TArray<AGravityVolumeObject> ObjectsInVolume;

	bool bLowGravityActive = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowMesh)
		{
			FVector ActorMiddle;
			FVector ActorExtents;
			GetActorBounds(false, ActorMiddle, ActorExtents);

			UStaticMeshComponent Mesh = UStaticMeshComponent::Create(this);
			Mesh.SetStaticMesh(MeshAsset);
			Mesh.SetMaterial(0, Material);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

			Mesh.SetWorldLocation(ActorMiddle);
			Mesh.SetWorldScale3D(FVector(ActorExtents.X/50.f, ActorExtents.Y/50.f, ActorExtents.Z/50.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		System::SetTimer(this, n"FindObjectsInVolume", 0.2f, false);

		/*TArray<AActor> Actors;
		GetOverlappingActors(Actors, AHazePlayerCharacter::StaticClass());
		for (AActor Actor : Actors)
		{
			ActorBeginOverlap(Actor);
		}*/
	}

	UFUNCTION(NotBlueprintCallable)
	void FindObjectsInVolume()
	{
		TArray<AActor> Actors;
		GetOverlappingActors(Actors, AGravityVolumeObject::StaticClass());
		for (AActor CurActor : Actors)
		{
			AGravityVolumeObject Object = Cast<AGravityVolumeObject>(CurActor);
			if (Object != nullptr)
			{
				ObjectsInVolume.Add(Object);
			}
		}
	}

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInVolume.AddUnique(Player);

        if(bLowGravityActive)
			ApplyGravityModifersToPlayer(Player);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInVolume.Remove(Player);

        if(bLowGravityActive)
			ClearGravityModifiersFromPlayer(Player);
    }

	UFUNCTION()
	void ActivateVolume()
	{
		for (AGravityVolumeObject CurObject : ObjectsInVolume)
		{
			CurObject.LowGravityActivated();
		}

		for (AHazePlayerCharacter Player : PlayersInVolume)
		{
			ApplyGravityModifersToPlayer(Player);
		}
	}

	UFUNCTION()
	void DeactivateVolume()
	{
		for (AGravityVolumeObject CurObject : ObjectsInVolume)
		{
			CurObject.LowGravityDeactivated();
		}

		for (AHazePlayerCharacter Player : PlayersInVolume)
		{
			ClearGravityModifiersFromPlayer(Player);
		}
	}

	void ApplyGravityModifersToPlayer(AHazePlayerCharacter Player)
	{
		Player.ApplySettings(LowGravityMovementSettings, this);
		Player.ApplySettings(LowGravityJumpSettings, this);
		Player.ApplySettings(LowGravityAirDashSettings, this);

		Player.BlockCapabilities(MovementSystemTags::SkyDive, this);
		Player.ApplyPivotLagSpeed(FVector(0.5f, 0.5f, 0.38f), this);

		Player.ApplyIdealDistance(1500.f, FHazeCameraBlendSettings(3.f), this);
	}

	void ClearGravityModifiersFromPlayer(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(MovementSystemTags::SkyDive, this);
		Player.ClearPivotLagSpeedByInstigator(this);
		UMovementSettings::ClearGravityMultiplier(Player, this);

		Player.ClearIdealDistanceByInstigator(this, 3.f);
	}
}