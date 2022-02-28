import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PickUp.MagneticPickupDataAsset;

UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMagnetPickupComponent : UMagneticComponent
{
	UPROPERTY()
	UMagneticPickupDataAsset MagneticPickupDataAsset;

	ECollisionEnabled OriginalPickupMeshCollision;
	UMeshComponent PickupMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PickupMesh = UMeshComponent::Get(Owner);
		if(PickupMesh != nullptr)
			OriginalPickupMeshCollision = PickupMesh.GetCollisionEnabled();
	}

	void CancelPickupLevitation(FVector OriginalLocation)
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.SetCapabilityAttributeVector(n"LevitationRevertLocation", OriginalLocation);
		HazeOwner.AddCapability(n"MagneticPickupCancelCapability");
	}

	void DisablePickupMeshCollision()
	{
		PickupMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	void RestorePickupMeshCollision()
	{
		PickupMesh.SetCollisionEnabled(OriginalPickupMeshCollision);
	}
}