import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Input Actor Cooking LOD")
class AVinylRecord : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent VinylRecordMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongReactionComponent SongReaction;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> Meshes;

	UPROPERTY(Category = "Properties")
	EVinylRecordType Type = EVinylRecordType::Full;

	UPROPERTY(Category = "Properties")
	float RotationRate = 50.f;
	UPROPERTY(Category = "Properties")
	float ScratchSpeed = 150.f;
	UPROPERTY(Category = "Properties")
	float ScratchIntensity = 20.f;

	float ScratchTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		switch (Type)
		{
			case EVinylRecordType::Full:
				VinylRecordMesh.SetStaticMesh(Meshes[0]);
			break;
			case EVinylRecordType::ThreeQuarters:
				VinylRecordMesh.SetStaticMesh(Meshes[1]);
			break;
			case EVinylRecordType::Half:
				VinylRecordMesh.SetStaticMesh(Meshes[2]);
			break;
			case EVinylRecordType::Quarter:
				VinylRecordMesh.SetStaticMesh(Meshes[3]);
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (SongReaction.IsAffectedBySongOfLife())
		{
			ScratchTime += DeltaTime;
			float CurRot = FMath::Sin(-ScratchTime * ScratchIntensity);
			AddActorLocalRotation(FRotator(0.f, CurRot * ScratchSpeed * DeltaTime, 0.f));
		}
		else
		{
			ScratchTime = 0.f;
			AddActorLocalRotation(FRotator(0.f, RotationRate * DeltaTime, 0.f));
		}
	}
}

enum EVinylRecordType
{
	Full,
	ThreeQuarters,
	Half,
	Quarter
}