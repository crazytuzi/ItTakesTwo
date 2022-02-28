import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyCharger;

event void FChargableSignature();

class UCastleChargableComponent : UActorComponent
{
	UPROPERTY()
	FChargableSignature OnCharge;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bWasHit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Find the charger, must be in the same level
		TArray<ACastleEnemyCharger> Chargers;
		GetAllActorsOfClass(Chargers);

		for (auto Charger : Chargers)
		{
			if (Charger.Level != Owner.Level)
				continue;
			Charger.Chargeables.Add(this);
		}
	}

	UFUNCTION()
	void HitChargableActor()
	{
		if (HasControl())
			NetHitChargableActor();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetHitChargableActor()
	{
		bWasHit = true;
		OnCharge.Broadcast();
	}
}