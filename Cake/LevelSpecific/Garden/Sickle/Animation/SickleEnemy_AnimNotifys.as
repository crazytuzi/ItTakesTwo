import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;

// This will make a ai not move
UCLASS(NotBlueprintable, meta = ("GardenSickleEnemyLockMovement"))
class UAnimNotify_GardenSickleEnemyLockMovement : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GardenSickleEnemyLockMovement";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration)const
	{
		auto GardenEnemy = Cast<ASickleEnemy>(MeshComp.GetOwner());	
		if(GardenEnemy != nullptr && GardenEnemy.HasControl())
		{
			GardenEnemy.BlockMovementWithInstigator(Animation);
		}
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation)const
	{
		auto GardenEnemy = Cast<ASickleEnemy>(MeshComp.GetOwner());	
		if(GardenEnemy != nullptr && GardenEnemy.HasControl())
		{
			GardenEnemy.UnblockMovementWithInstigator(Animation);
		}
		return true;
	}
};

// This will make a ai trigger a ground impact and hurt the player if it is in range
UCLASS(NotBlueprintable, meta = ("GardenSickleEnemyTriggerImpact"))
class UAnimNotify_GardenSickleEnemyTriggerImpact : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GardenSickleEnemyTriggerImpact";
	}

	// UFUNCTION(BlueprintOverride)
	// bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	// {
	// 	auto GardenEnemy = Cast<ASickleEnemy>(MeshComp.GetOwner());	
	// 	if(GardenEnemy != nullptr && GardenEnemy.HasControl())
	// 	{
	// 		GardenEnemy.SetCapabilityActionState(GardenSickle::TriggerAttack, EHazeActionState::ActiveForOneFrame);
	// 	}
	// 	return false;
	// }
};