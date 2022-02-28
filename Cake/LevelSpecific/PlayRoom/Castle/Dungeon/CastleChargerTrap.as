import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

event void FOnChargerTrapped();
event void FOnChargerKilled();

class ACastleChargerTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default RootComp.SetbVisualizeComponent(true);

	UPROPERTY()
	ACastleEnemy Charger;

	UPROPERTY()
	bool bActive = false;

	UPROPERTY()
	bool bTrapped = false;

	UPROPERTY()
	const float HorizontalAcceptanceDistance = 200.f;
	UPROPERTY()
	const float ForwardAcceptanceDistance = 400.f;

	UPROPERTY()
	FOnChargerTrapped OnChargerTrapped;

	UPROPERTY()
	FOnChargerKilled OnChargerKilled;

	bool bHalfKilled;
	bool bKilled;
	float RespawnTimer = 3.f;
	float RespawnTracker;
}