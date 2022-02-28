import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;

const FStatID STAT_SnowFolkVisibility(n"SnowFolkVisiblity");
const FTransform HiddenTransform(FVector(0.f, 0.f, -100000.f));

// Used to convert from SkelMesh -> Lod Static Mesh
class USnowFolkLodLookupDataAsset : UDataAsset
{
	UPROPERTY(Category = "Default")
	UStaticMesh DefaultMesh;

	UPROPERTY(Category = "Lookup")
	TMap<USkeletalMesh, UStaticMesh> Lookup;

	UStaticMesh GetMeshForSkeleton(USkeletalMesh Skel)
	{
		if (!Lookup.Contains(Skel))
			return DefaultMesh;

		return Lookup[Skel];
	}
}

UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class ASnowFolkVisibilityManager : AHazeActor
{
	default TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Root;

	UPROPERTY()
	USnowFolkLodLookupDataAsset LookupAsset;

	UPROPERTY(Category = "Folk", EditConst)
	TArray<ASnowfolkSplineFollower> Snowfolk;
	TArray<UStaticMeshComponent> LodMeshes;

	UFUNCTION(CallInEditor, Category = "Folk")
	void FillSnowfolkList()
	{
		TArray<ASnowfolkSplineFollower> SnowfolkInOtherLevel;
		LodMeshes.Empty();

		GetAllActorsOfClass(Snowfolk);
		for(auto Folk : Snowfolk)
		{
			if (Folk.Level != Level)
			{
				Print("Snowfolk '" + Folk + "' is not placed in the same level as movement manager", 10, FLinearColor::Red);
				SnowfolkInOtherLevel.Add(Folk);
			}
		}

		for(auto Folk : SnowfolkInOtherLevel)
		{
			Snowfolk.Remove(Folk);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LodMeshes.SetNum(Snowfolk.Num());

		if (LookupAsset == nullptr)
		{
			Print("Snowfolk LOD lookup asset was not set!", 15.f, FLinearColor::Red);
			return;
		}

		SetActorTransform(FTransform());
	}

	UStaticMeshComponent CreateLodMeshForFolk(int Index, ASnowfolkSplineFollower Folk)
	{
		UStaticMesh StaticMesh = LookupAsset.GetMeshForSkeleton(Folk.SkeletalMeshComponent.SkeletalMesh);

		auto StaticMeshComp = UStaticMeshComponent::Create(this);
		StaticMeshComp.AttachToComponent(Root);
		StaticMeshComp.StaticMesh = StaticMesh;
		StaticMeshComp.WorldScale3D = Folk.SkeletalMeshComponent.WorldScale;
		StaticMeshComp.SetCollisionProfileName(n"NoCollision");

		LodMeshes[Index] = StaticMeshComp;
		return StaticMeshComp;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if TEST
		FScopeCycleCounter EntryCounter(STAT_SnowFolkVisibility);
#endif

		FTransform Transform;
		for(int i=0; i<Snowfolk.Num(); ++i)
		{
			auto Mesh = LodMeshes[i];
			auto Folk = Snowfolk[i];

			Folk.UpdateDetailLevel();
			if (Folk.bIsSnowfolkVisible || Folk.DetailLevel == ESnowFolkDetailLevel::Hidden)
			{
				if (Mesh != nullptr && Mesh.IsVisible())
					Mesh.SetHiddenInGame(true);
			}
			else
			{
				if (Mesh == nullptr)
					Mesh = CreateLodMeshForFolk(i, Folk);

				if (!Mesh.IsVisible())
					Mesh.SetHiddenInGame(false);

				Transform = Folk.MovementComp.CurrentTransform;
				Transform.Scale3D = Mesh.WorldScale;

				Mesh.WorldTransform = Transform;
			}
		}
	}
}