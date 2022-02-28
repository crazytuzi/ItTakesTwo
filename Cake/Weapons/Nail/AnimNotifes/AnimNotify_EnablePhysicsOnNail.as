import Cake.Weapons.Nail.NailWeaponActor;

UCLASS(NotBlueprintable, meta = ("SimulatePhysics"))
class UAnimNotify_EnablePhysicsOnNail : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SimulatePhysics";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		ANailWeaponActor Nail = Cast<ANailWeaponActor>(MeshComp.GetOwner());	

		if(Nail == nullptr)
			return false;

		// cache normal settings
		Nail.Mesh.DisableAndCachePhysicsSettings();
		Nail.Mesh.EnableAndApplyCachedPhysicsSettings();

		// apply temp settings
		Nail.Mesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Nail.Mesh.SetSimulatePhysics(true);

		return true;
	}

};