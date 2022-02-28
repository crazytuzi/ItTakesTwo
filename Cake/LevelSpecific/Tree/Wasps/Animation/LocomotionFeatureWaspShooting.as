import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;

struct FWaspShootingAnims
{
    UPROPERTY()
    UAnimSequence Wasp = nullptr;

    UPROPERTY()
    UAnimSequence Weapon = nullptr;
}

class ULocomotionFeatureWaspShooting : UHazeLocomotionFeatureBase
{
    ULocomotionFeatureWaspShooting()
    {
        Tag = n"WaspShooting";
    }

    UPROPERTY(Category = "Shooting")
    FWaspShootingAnims SingleShot;

    UPROPERTY(Category = "Shooting")
    FWaspShootingAnims BurstShot;

    UPROPERTY(Category = "Shooting")
    FWaspShootingAnims InitialTaunt;

    UPROPERTY(Category = "Shooting")
    FWaspShootingAnims TakeDamage;

	FWaspShootingAnims GetSingleAnimation(EWaspAnim AnimType, uint8 Variant) const
	{
		if (AnimType == EWaspAnim::None)
			return FWaspShootingAnims();
		if (AnimType == EWaspAnim::ShootSingle)
			return SingleShot;
		if (AnimType == EWaspAnim::ShootBurst)
			return BurstShot;
		if (AnimType == EWaspAnim::InitialTaunt)
			return InitialTaunt;
		if (AnimType == EWaspAnim::TakeDamage)
			return TakeDamage;

		return FWaspShootingAnims();
	}
}