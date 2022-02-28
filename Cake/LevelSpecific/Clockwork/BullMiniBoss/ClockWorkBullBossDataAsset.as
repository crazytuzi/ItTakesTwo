
import Cake.LevelSpecific.Clockwork.BullMiniBoss.LocomotionFeature.LocomotionFeatureClockworkBullBossPlayer;

struct FBullBossPlayerSetupInformation
{
	UPROPERTY()
	UHazeCapabilitySheet Sheet;

	UPROPERTY()
	EHazeCapabilitySheetPriority SheetPriority = EHazeCapabilitySheetPriority::Normal;
};

// SETTINGS
class UClockworkBullBossAiSettings : UDataAsset
{
	/* The bull will start attacking the player inside this distance */
	UPROPERTY(Category = "Target")
	float CanSeeTargetRange = 2400.f;

	/* Direction to the player dot with forward vector greater then this value = can see the target */
	UPROPERTY(Category = "Target", Meta=(ClampMin = 0.f, ClampMax = 1.f))
	float CanSeeTargetAngle = 30.f;

	// How long time if the impact is the same type until it can trigger again.
	UPROPERTY(Category = "Target")
	float SameImpactCooldown = 0.25f;

	// How long until the same target can be selected again
	UPROPERTY(Category = "Target")
	FHazeMinMax DisableSameTargetTime = FHazeMinMax(1.f, 1.f);

	// When it is time to select a new target, the bigger this value is, the bigger the chance to select a random target, and not the best target
	UPROPERTY(Category = "Target", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float RandomFactorWhenSelectingTarget = 0.5f;

	/* Select the closest player
	 * If we cant see any target, 
	 * and the random factor has not kicked in
	 * and the time since we had a target is bigger than this amount,
	*/
	UPROPERTY(Category = "Target")
	float MaxTimeWithoutTarget = 3.f;

	// How long until the bull can charge may again
	UPROPERTY(Category = "Target")
	FHazeMinMax ChargeCooldown = FHazeMinMax(0.f, 0.f);

	// How long until the bull can charge may the first time
	UPROPERTY(Category = "Target")
	float InitialChargeCooldown = 0.f;

	// How Many times the bullboss will perform the charge attack after eachother
	UPROPERTY(Category = "Target")
	int ChargeTimes = 1;

	// How big the chance is that the charge will trigger instead of the attack
	UPROPERTY(Category = "Target", meta = (ClampMin = "0.05", ClampMax = "1.0", UIMin = "0.05", UIMax = "1.0"))
	float ChargeChance = 0.8f;

	// How far ahead when charching, the imapct to may will trigger
	UPROPERTY(Category = "Target")
	float ChargeImpactOffsetDistance = 0;

	// If true, the charge will only happen when may is the current target
	// Else, she will become the current target
	UPROPERTY(Category = "Target")
	bool bChargeRequiresMayToBeCurrentTarget = false;
}