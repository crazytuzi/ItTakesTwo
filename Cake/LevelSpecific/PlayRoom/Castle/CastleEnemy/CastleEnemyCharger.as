import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Interactions.InteractionComponent;
import Vino.PlayerHealth.PlayerDamageEffect;

/**
 * Players in this volume will be charged with high priority
 * if no chargeables are alive anymore.
 */
class ACastleChargerLowPriorityVolume : AVolume
{
};

event void FOnChargerHitWall();

class ACastleEnemyCharger : ACastleEnemy
{
	// Never get aggro, we'll only be switching targets from 'ForceChargerTarget' in level BP
	default bCanAggro = false;
	default bChangeNetworkSideOnAggro = false;

	UPROPERTY(DefaultComponent)
	UInteractionComponent LeftHandInteraction;

	UPROPERTY(DefaultComponent)
	UInteractionComponent RightHandInteraction;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMovementEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovementEvent;

	UPROPERTY()
	FOnChargerHitWall OnChargerHitWall;

	UPROPERTY()
	float ChargePlayerDamage = 0.5f;

	// If a player is standing within this range of
	// a chargeable, prioritize that player.
	UPROPERTY()
	float NearbyChargeablePriorityRange = 600.f;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> ChargePlayerDamageEffect;

	UPROPERTY()
	UForceFeedbackEffect ChargePlayerDamageForceFeedback;

	UPROPERTY()
	int ChargeEnemyDamage = 40;

	// List of chargeables that are in the level
	TArray<UObject> Chargeables;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		LeftHandInteraction.Disable(n"ChargerTrap");
		RightHandInteraction.Disable(n"ChargerTrap");
		HazeAkComp.SetTrackVelocity(true, 1000.f);
		HazeAkComp.HazePostEvent(StartMovementEvent);
	}
}