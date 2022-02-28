import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.CastleChessBossWave;
class UCastleChessBossAbilitiesComponent : UActorComponent
{
	UPROPERTY()
	float CooldownBetweenAbilities = 5.f;

	UPROPERTY()
	float CooldownBetweenAbilitiesCurrent = CooldownBetweenAbilities;

	UPROPERTY()
	TArray<FCastleChessWave> AbilityWaves;
	FCastleChessWave PreviousWave;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CooldownBetweenAbilitiesCurrent > 0.f)
			CooldownBetweenAbilitiesCurrent -= DeltaTime;
	}

	void AbilityActivated()
	{
		CooldownBetweenAbilitiesCurrent = CooldownBetweenAbilities;
	}

	void RequestWave(FCastleChessWave Wave)
	{
		AbilityWaves.Add(Wave);
	}
}