import Cake.LevelSpecific.Garden.Sickle.Player.SickleAttackData;

class ULocomotionSickleStateMachineAsset : UHazeLocomotionStateMachineAsset
{
	UPROPERTY()
	FHazePlayOverrideAnimationParams EquipAnimation;

	UPROPERTY()
	FHazePlayOverrideAnimationParams UnequipAnimation;

	UPROPERTY(Category = "Attacks")
	TArray<USickleAttackDataAsset> Attacks;
}