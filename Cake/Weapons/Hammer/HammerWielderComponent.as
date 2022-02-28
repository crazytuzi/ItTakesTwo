
import Cake.Weapons.Hammer.HammerWeaponActor;

/*
 *	Commonplace for hammer weapon data on the player 
 */

event void FHammerWeaponConeSmash(FHitResult HammerNoseHitData);
event void FHammerSwingSwitchedDirection();
event void FHammerSwingStarted();
event void FHammerSwingEnded();

class UHammerWielderComponent : UActorComponent 
{
	private AHammerWeaponActor HammerActor = nullptr;
	private bool bOngoingHammeringAnimation = false;		

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHammerSwingSwitchedDirection OnHammerSwingSwitchedDirection;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHammerSwingStarted OnHammerSwingStarted;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHammerSwingEnded OnHammerSwingEnded;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FHammerWeaponConeSmash OnHammerHit;

	float TimeStampAnimationStarted = BIG_NUMBER;

	// Transients
	//////////////////////////////////////////////////////////////////////////
	// Functions

	UFUNCTION(Category = "Weapon|Hammer")
	AHammerWeaponActor GetHammer() property
	{
		return HammerActor;
	}

	void SetHammer(AHammerWeaponActor InHammer) property
	{
		HammerActor = InHammer;
	}

	UFUNCTION(Category = "Weapon|Hammer")
	bool IsDoingHammeringAnimation() 
	{
		return bOngoingHammeringAnimation;
	}

	void SetDoingHammeringAnimation(bool bDoingSmash)
	{
		bOngoingHammeringAnimation = bDoingSmash;
	}

};
