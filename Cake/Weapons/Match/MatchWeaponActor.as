import Cake.Weapons.Match.MatchProjectileActor;

event void FMatchWeaponShootEvent();

UCLASS(abstract)
class AMatchWeaponActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ShotFiredEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LastShotFiredEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EmptyShotFiredEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReloadEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FullyReloadedEvent;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FMatchWeaponShootEvent OnMatchShoot;

	default Mesh.bOwnerNoSee = false;
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPose;
	default Mesh.bCastDynamicShadow = true;
	default Mesh.bAffectDynamicIndirectLighting = true;
	default Mesh.bCanEverAffectNavigation = false;
	default Mesh.SetAnimationMode(EAnimationMode::AnimationSingleNode);
	default Mesh.SetApplyRootMotionToOwnerRoot(true);
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default Mesh.SetCollisionProfileName(n"WeaponDefault");
	default Mesh.BodyInstance.bNotifyRigidBodyCollision = false;
	default Mesh.SetGenerateOverlapEvents(false);

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	private AHazeActor WielderCurrent = nullptr;
	private AMatchProjectileActor LoadedMatchProjectile = nullptr;

	// Transients 
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	UFUNCTION()
	AMatchProjectileActor GetLoadedMatch() const
	{
		return LoadedMatchProjectile;
	}

	UFUNCTION()
	void SetLoadedMatch(AMatchProjectileActor InMatch)
	{
		LoadedMatchProjectile = InMatch;
		if(LoadedMatchProjectile != nullptr)
		{
			LoadedMatchProjectile.HandleLoaded();
			LoadedMatchProjectile.CallOnHandleLoaded();
		}
	}

	UFUNCTION(BlueprintPure, Category = "Weapon|MatchWeapon")
	AHazeActor GetWielder() const
	{
		return WielderCurrent;
	}

	UFUNCTION(BlueprintCallable, Category = "Weapon|MatchWeapon")
	void SetWielder(AHazeActor NewWielder)
	{
		WielderCurrent = NewWielder;
	}

	void ShootMatch(FMatchTargetData TargetData)
	{
		OnMatchShoot.Broadcast();
		LoadedMatchProjectile.Launch(TargetData);
		LoadedMatchProjectile = nullptr;		
	}

	AMatchProjectileActor TakeMatchToShoot()
	{
		auto Match = LoadedMatchProjectile;
		LoadedMatchProjectile = nullptr;
		return Match;
	}

	void DelayedShootMatch(AMatchProjectileActor Match, FMatchTargetData TargetData)
	{
		Match.Launch(TargetData);
	}

};