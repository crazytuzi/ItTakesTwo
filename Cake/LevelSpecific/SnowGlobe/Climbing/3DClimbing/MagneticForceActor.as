UCLASS(Abstract)
class AMagneticForceActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	UStaticMeshComponent RootComp;
	default RootComp.CollisionProfileName = n"OverlapAll";
	default RootComp.CollisionObjectType = ECollisionChannel::ECC_WorldDynamic;
	//default RootComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default RootComp.SetbHiddenInGame(true);
	
	UPROPERTY()
    UObject RedMaterial = Asset("/Game/Developers/Bazzman/Dev_Swatch_Glass_MagnetPositive.Dev_Swatch_Glass_MagnetPositive");
	UPROPERTY()
    UObject BlueMaterial = Asset("/Game/Developers/Bazzman/Dev_Swatch_Glass_MagnetNegative.Dev_Swatch_Glass_MagnetNegative");

	bool bPositive = false;
	bool bActivated;

	UMaterialInstanceDynamic RedMaterialInstance;
	UMaterialInstanceDynamic BlueMaterialInstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BlueMaterialInstance = Material::CreateDynamicMaterialInstance(Cast<UMaterialInstance>(BlueMaterial));
		RedMaterialInstance = Material::CreateDynamicMaterialInstance(Cast<UMaterialInstance>(RedMaterial));

		RootComp.SetMaterial(0, BlueMaterialInstance);
	}

	UFUNCTION()
	void ActivateForce(float Radius, bool IsPositive)
	{
		if(IsPositive != bPositive)
		{
			if(IsPositive)
			{
				RootComp.SetMaterial(0, RedMaterialInstance);
				bPositive = true;
			}
			else
			{
				RootComp.SetMaterial(0, BlueMaterialInstance);
				bPositive = false;
			}
		}
		RootComp.SetHiddenInGame(false);
		
		float ScaleSize = Radius/50.0f;
		FVector NewScale = FVector(ScaleSize, ScaleSize, ScaleSize);
		RootComp.SetWorldScale3D(NewScale);
		bActivated = true;
		RootComp.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	}

	UFUNCTION()
	void DectivateForce()
	{
		RootComp.SetHiddenInGame(true);
		bActivated = false;
		RootComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	}


	UFUNCTION()
	void CheckScale(float Radius)
	{
		if(RootComp.WorldScale.X != Radius / 50.0f)
		{
			float ScaleSize = Radius/50.0f;
			FVector NewScale = FVector(ScaleSize, ScaleSize, ScaleSize);
			RootComp.SetWorldScale3D(NewScale);
		}
	}

}
