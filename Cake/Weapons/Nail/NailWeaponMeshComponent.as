
UCLASS(HideCategories = "Cooking ComponentReplication Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset")
class UNailWeaponMeshComponent : UHazeCharacterSkeletalMeshComponent
{
	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default SetCollisionProfileName(n"WeaponDefault");
	default BodyInstance.bNotifyRigidBodyCollision = false;
	default SetGenerateOverlapEvents(false);

	default bCastDynamicShadow = true;
	default bAffectDynamicIndirectLighting = true;
	default bCanEverAffectNavigation = false;

	// needed for high speed collision.
  	default BodyInstance.bUseCCD = true;		

	default AddTag(ComponentTags::HideOnCameraOverlap);

    UPROPERTY(Category = "Animation|Defaults", meta = (ShowOnlyInnerProperties))
	FHazePlaySlotAnimationParams AnimParams_OnBackMH;

    UPROPERTY(Category = "Animation|Defaults", meta = (ShowOnlyInnerProperties))
	FHazePlaySlotAnimationParams AnimParams_PiercedMH;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients

	UPROPERTY()
	int AssignedIndex = -1;		// -1 == unassigned

	protected ECollisionEnabled PreAttachment_CollisionType = ECollisionEnabled::NoCollision;
	protected bool PreAttachment_SimulatePhysics = false;
	protected bool bCollisionSettingsAreCached = false;

	// Transients
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	/* Needs to be done BEFORE we attach the weapon to something */
	void DisableAndCachePhysicsSettings()
	{
		if (bCollisionSettingsAreCached)
			return;

		PreAttachment_CollisionType = GetCollisionEnabled();
		PreAttachment_SimulatePhysics = IsSimulatingPhysics();
		SetSimulatePhysics(false);
		SetCollisionEnabled(ECollisionEnabled::NoCollision);
		bCollisionSettingsAreCached = true;
	}

	/* Needs to be done AFTER we attach the weapon to something */
	void EnableAndApplyCachedPhysicsSettings()
	{
		if (!bCollisionSettingsAreCached)
			return;

		SetCollisionEnabled(PreAttachment_CollisionType);
		SetSimulatePhysics(PreAttachment_SimulatePhysics);
		bCollisionSettingsAreCached = false;
	}

}
