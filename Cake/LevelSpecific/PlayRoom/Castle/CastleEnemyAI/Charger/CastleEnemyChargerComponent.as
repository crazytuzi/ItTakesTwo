import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargeSettings;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.CastleChargerTrap;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.Charger.CastleChargerRockfall;

class UCastleEnemyChargerComponent : UActorComponent
{
	AHazeActor ChargeTarget;
	bool bHasTelegraphed = false;
	bool bHasTurnedPostStun = true;
	bool bShouldTriggerRockfall = false;

	UPROPERTY()
	UNiagaraSystem RockfallImpact;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RoofRumbleEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RockFallImpactEvent;

	UPROPERTY()
	TSubclassOf<ACastleChargerRockfall> RockfallType;

	UPROPERTY()
	AHazeActor CenterOfArena;

	UPROPERTY()
	ACastleChargerTrap Trap;

	bool bChargerTrapped = false;

	UPROPERTY()
	TSubclassOf<ACastleEnemy> ChargerHandType;
	ACastleEnemy ChargerHand1;
	ACastleEnemy ChargerHand2;
	int SpawnHandCounter1 = 0;
	int SpawnHandCounter2 = 0;

	// Used in the ABP
	UPROPERTY(BlueprintReadOnly)
	bool bHandHurt = false;
	UPROPERTY(BlueprintReadOnly)
	bool bRightHandHurt;
	UPROPERTY(BlueprintReadOnly)
	bool bDead = false;

	UPROPERTY()
	bool bTurningRight;

	UPROPERTY()
	float StunDuration = 0.f;
	UPROPERTY()
	float StunDurationMax = ChargerSettings::ChargeStunTime;

	UPROPERTY(Category = "Effects|Charge")
	UNiagaraSystem ChargeTrailEffect;

	UPROPERTY(Category = "Effects|Stun")
	UNiagaraSystem StunEffect;

	UPROPERTY(Category = "Effects|Stun")
	TSubclassOf<UCameraShakeBase> StunCameraShake;

	void ResetCharger()
	{
		ChargeTarget = nullptr;
		bHasTelegraphed = false;
	}
}