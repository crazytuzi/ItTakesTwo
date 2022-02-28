
import Cake.Weapons.Hammer.HammerWeaponSettings;

/**
 * Hammer Weapon Actor. 
 */

event void FHammerWeaponEquippedEventSignature(AHazePlayerCharacter Wielder);
event void FHammerWeaponUnequippedEventSignature(AHazePlayerCharacter Wielder);

UCLASS(abstract)
class AHammerWeaponActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	default Mesh.bOwnerNoSee = false;
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPose;
	default Mesh.bCastDynamicShadow = true;
	default Mesh.bAffectDynamicIndirectLighting = true;
	default Mesh.SetCollisionProfileName(n"WeaponDefault");
	default Mesh.SetGenerateOverlapEvents(false);
	default Mesh.bCanEverAffectNavigation = false;
	default Mesh.SetAnimationMode(EAnimationMode::AnimationSingleNode);
	default Mesh.SetApplyRootMotionToOwnerRoot(true);
	default Mesh.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
	default Mesh.SetCollisionProfileName(n"WeaponDefault");
	default Mesh.BodyInstance.bNotifyRigidBodyCollision = true;
	default Mesh.SetGenerateOverlapEvents(true);
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwingStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwingDirectionChangeEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwingStopEvent;

	UPROPERTY(Category = "Settings")
	UHammerWeaponSettings DefaultSettings = nullptr;

	/* When the nail weapon is equipped on the character. (Also trigger on recalls) */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHammerWeaponEquippedEventSignature OnHammerEquipped;
		
	/* When the nail is unequipped or thrown */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHammerWeaponUnequippedEventSignature OnHammerUnequipped;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	private AHazeActor WielderCurrent = nullptr;
	private AHazeActor WielderPrevious = nullptr;

	// Transients 
	//////////////////////////////////////////////////////////////////////////
	// functions

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Apply defaults 
		if (DefaultSettings != nullptr)
			ApplySettings(DefaultSettings, this, EHazeSettingsPriority::Defaults);
	}

	/* returns the actor which is wielding the weapon. */
	UFUNCTION(BlueprintPure, Category = "Weapon")
	AHazeActor GetWielder() const
	{
		return WielderCurrent;
	}

	/* returns the actor which previously wielded the weapon. 
		(will return NULL unless the weapon has been Equipped twice.) */
	UFUNCTION(BlueprintPure, Category = "Weapon")
		AHazeActor GetPreviousWielder() const
	{
		return WielderPrevious;
	}

	void SetWielder(AHazeActor NewWielder)
	{
		if (NewWielder == WielderCurrent)
			return;

		WielderPrevious = GetWielder();
		WielderCurrent = NewWielder;
	}

	FVector HammerNoseOffset = FVector(131.f, 0.f, 0.f);
	float HammerNoseRadius = 50.f;

	bool SphereTraceHammerNoseForHit(FHitResult& OutHitData, FVector InGroundNormal = FVector::UpVector)
	{
		const FTransform MayTransform = Game::GetMay().GetActorTransform();
		const FVector NosePos = MayTransform.TransformPosition(HammerNoseOffset);
		// const FVector NosePos = Mesh.GetSocketLocation(n"Nose");

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(GetWielder());
		ActorsToIgnore.Add(this);

		return System::SphereTraceSingle(
			NosePos,
			NosePos - InGroundNormal,
			HammerNoseRadius,
			ETraceTypeQuery::WeaponTrace,
			false,
			ActorsToIgnore,
			EDrawDebugTrace::None,
			// EDrawDebugTrace::Persistent,
			OutHitData,
			true
		);
	}

}