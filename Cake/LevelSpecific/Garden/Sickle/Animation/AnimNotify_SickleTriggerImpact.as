
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;

UCLASS(NotBlueprintable, meta = ("SickleTriggerImpact"))
class UAnimNotify_SickleTriggerImpact : UAnimNotify
{
	/* Make it possible to hit multiple enemies
	 * if true, all the enemies inside the arc will be hit
	 * if false, the current target will always be hit
	*/ 
	UPROPERTY()
	bool bHitMultipleEnemies = false;

	UPROPERTY(meta = (ShowOnlyInnerProperties, EditCondition = "bHitMultipleEnemies"))
	FSickleImpactArc IncludeAllEnemiesInRange;

	// When the player is attacking an enemy, she will be attached.
	// this will release the player from the current enemy
	UPROPERTY()
	bool bDetachPlayerIfAttached = true;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SickleTriggerImpact";
	}
};