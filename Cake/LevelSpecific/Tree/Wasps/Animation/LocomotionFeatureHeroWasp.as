struct FWaspThreeShotSequence
{
    UPROPERTY(Category = "Attacks")
    UAnimSequence Start;

    UPROPERTY(Category = "Attacks")
    UAnimSequence MH;

    UPROPERTY(Category = "Attacks")
    UAnimSequence End;
}

struct FWaspSyncedAnimSet
{
    UPROPERTY(Category = "Attacks|Grappling")
    UAnimSequence Wasp;

    UPROPERTY(Category = "Attacks|Grappling")
    UAnimSequence Cody;

    UPROPERTY(Category = "Attacks|Grappling")
    UAnimSequence May;

    UAnimSequence GetPlayerAnimation(AHazePlayerCharacter Player)
    {
        if (Player.IsCody())
            return Cody;
        if (Player.IsMay())
            return May;
        ensure(false);
        return nullptr;
    }
}

struct FWaspResponseAnimSet
{
    UPROPERTY(Category = "Attacks")
    UAnimSequence Cody;

    UPROPERTY(Category = "Attacks")
    UAnimSequence May;

    UAnimSequence GetPlayerAnimation(AHazePlayerCharacter Player)
    {
        if (Player.IsCody())
            return Cody;
        if (Player.IsMay())
            return May;
        ensure(false);
        return nullptr;
    }
}

enum EWaspAnim
{
	None,
	Attacks,
	Grapple_Attack,
	Taunts,
	Dash,
	Hover,
	StunnedBySap,
	ShakeOffSap,
	TakeDamage,	
	ShootSingle,
	ShootBurst,
	Exhausted,
	TauntExposed,
	InitialTaunt,
}

class ULocomotionFeatureHeroWasp : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureHeroWasp()
    {
        Tag = n"HeroWasp";
    }

    UPROPERTY(Category = "Attacks")
    TArray<FWaspThreeShotSequence> Attacks;

    UPROPERTY(Category = "Attacks|Grappling")
    FWaspThreeShotSequence Grapple_Attack;

    UPROPERTY(Category = "Attacks|Grappling")
    FWaspSyncedAnimSet Grapple_Enter;

    UPROPERTY(Category = "Attacks|Grappling")
    FWaspSyncedAnimSet Grapple_MH;

    UPROPERTY(Category = "Attacks|Grappling")
    FWaspSyncedAnimSet Grapple_Aborted;

    UPROPERTY(Category = "Attacks|Grappling")
    FWaspSyncedAnimSet Grapple_Kill;

   	UPROPERTY(Category = "Attacks|Grappling")
	UHazeCameraSettingsDataAsset Grapple_CameraSettings;

    UPROPERTY(Category = "Taunts")
    TArray<UAnimSequence> Taunts;

    UPROPERTY(Category = "Taunts")
	UAnimSequence InitialTaunt;

    UPROPERTY(Category = "Taunts")
	UAnimSequence TauntExposed;

    UPROPERTY(Category = "Movement")
    UAnimSequence Dash;

    UPROPERTY(Category = "Movement")
    UAnimSequence Hover;

    UPROPERTY(Category = "Movement")
    UAnimSequence Exhausted;

    UPROPERTY(Category = "Movement")
    UAnimSequence ExhaustedRecover;

    UPROPERTY(Category = "HitResponses")
    UAnimSequence StunnedBySap;

    UPROPERTY(Category = "HitResponses")
    UAnimSequence ShakeOffSap;

    UPROPERTY(Category = "HitResponses")
    UAnimSequence TakeDamage;

	bool GetThreeshotAnimation(EWaspAnim AnimType, uint8 Variant, FWaspThreeShotSequence& ThreeShot) const
	{
		ThreeShot.Start = nullptr;
		ThreeShot.MH = nullptr;	
		ThreeShot.End = nullptr;

		if (AnimType == EWaspAnim::None)
			return false;

		if (AnimType == EWaspAnim::Attacks)
		{
			if (!Attacks.IsValidIndex(Variant))
				return false;
			ThreeShot = Attacks[Variant];
			return true;				
		}

		if (AnimType == EWaspAnim::Dash)
		{
			ThreeShot.MH = Dash;	
			return true;
		}

		if (AnimType == EWaspAnim::Hover)
		{
			ThreeShot.MH = Hover;	
			return true;
		}

		if (AnimType == EWaspAnim::Grapple_Attack)
		{
			ThreeShot = Grapple_Attack;
			return true;
		}

		// We want to play this looping currently. This will be replaced by blendspace.
		if (AnimType == EWaspAnim::ShakeOffSap)
		{
			ThreeShot.MH = ShakeOffSap;
			return true;
		}

		if (AnimType == EWaspAnim::Exhausted)
		{
			ThreeShot.MH = Exhausted;
			ThreeShot.End = ExhaustedRecover;
			return true;
		}

		return false;
	} 

	UAnimSequence GetSingleAnimation(EWaspAnim AnimType, uint8 Variant) const
	{
		if (AnimType == EWaspAnim::None)
			return nullptr;
		if (AnimType == EWaspAnim::Taunts)
		{
			if (!Taunts.IsValidIndex(Variant))
				return nullptr;
			return Taunts[Variant];
		}
		if (AnimType == EWaspAnim::StunnedBySap)
			return StunnedBySap;
		if (AnimType == EWaspAnim::TakeDamage)
			return TakeDamage;
		if (AnimType == EWaspAnim::InitialTaunt)
			return InitialTaunt;
		if (AnimType == EWaspAnim::TauntExposed)
			return TauntExposed;

		return nullptr;
	}
}
 
 