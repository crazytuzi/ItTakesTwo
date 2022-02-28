class ULocomotionFeatureWeaponUnequip : UHazeLocomotionFeatureBase
{
    default Tag = n"Unequip";

    UPROPERTY(Category = "Unequip")
    FHazePlaySequenceData Unequip; 

	UPROPERTY(Category = "Unequip")
    FHazePlaySequenceData UnequippedMh;

	UPROPERTY(Category = "Equip")
    FHazePlaySequenceData Equip;
	
};