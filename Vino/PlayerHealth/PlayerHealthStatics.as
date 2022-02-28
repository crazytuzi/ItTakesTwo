import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;

/* Deal a certain percentage of the player's health in damage. */
UFUNCTION(Category = "Player Health")
void DamagePlayerHealth(AHazePlayerCharacter Player, float Damage, TSubclassOf<UPlayerDamageEffect> DamageEffect = TSubclassOf<UPlayerDamageEffect>(), TSubclassOf<UPlayerDeathEffect> DeathEffect = TSubclassOf<UPlayerDeathEffect>())
{
	if (!Player.HasControl())
		return;

	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	if (!HealthComp.CanTakeDamage())
		return;

	UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);

	// If the player would die from this damage, kill them instead
	if (HealthComp.WouldDieFromDamage(Damage))
	{
		HealthComp.LeaveDeathCrumb(DeathEffect, bKilledByDamage = true);
	}
	else
	{
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
		CrumbParams.AddObject(n"DamageEffect", DamageEffect.Get());
		CrumbParams.AddNumber(n"ResetCounter", HealthComp.ResetCounter);
		CrumbParams.AddValue(n"Damage", Damage);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(HealthComp, n"Crumb_DamagePlayerHealth"), CrumbParams);
	}
}

/* Heal a certain percentage of the player's health in damage. */
UFUNCTION(Category = "Player Health")
void HealPlayerHealth(AHazePlayerCharacter Player, float Heal)
{
	if (!Player.HasControl())
		return;

	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);

	if (HealthComp.bIsDead)
		return;

	FHazeDelegateCrumbParams CrumbParams;
	CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
	CrumbParams.AddValue(n"HealAmount", Heal);
	CrumbParams.AddNumber(n"ResetCounter", HealthComp.ResetCounter);
	CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(HealthComp, n"Crumb_HealPlayerHealth"), CrumbParams);
}

/* Immediately kill the player without taking into account the player's health. */
UFUNCTION(Category = "Player Health")
void KillPlayer(AHazePlayerCharacter Player, TSubclassOf<UPlayerDeathEffect> DeathEffect = TSubclassOf<UPlayerDeathEffect>())
{
	if (!Player.HasControl())
		return;

	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	if (!HealthComp.CanDie())
		return;

	HealthComp.LeaveDeathCrumb(DeathEffect);
}

/* Whether killing the player right now will have any effect. */
UFUNCTION(BlueprintPure, Category = "Player Health")
bool CanPlayerBeKilled(AHazePlayerCharacter Player)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	if (!HealthComp.CanDie())
		return false;
	return true;
}

/* Whether dealing damage to the player right now will have any effect. */
UFUNCTION(BlueprintPure, Category = "Player Health")
bool CanPlayerBeDamaged(AHazePlayerCharacter Player)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	if (!HealthComp.CanTakeDamage())
		return false;
	return true;
}

UFUNCTION(BlueprintPure, Category = "Player Health")
bool IsPlayerDead(AHazePlayerCharacter Player)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	return HealthComp.bIsDead;
}

UFUNCTION(BlueprintPure, Category = "Player Health")
bool IAnyPlayerDead()
{
	TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
	for (AHazePlayerCharacter Player : Players)
	{
		if (IsPlayerDead(Player))
			return true;
	}
	return false;
}

UFUNCTION(BlueprintPure, Category = "Player Health")
bool IsPlayerInIFrame(AHazePlayerCharacter Player)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	return HealthComp.InIFrame();
}

/* Forcably trigger the players to go game over right now. */
UFUNCTION(Category = "Player Health")
void TriggerPlayersGameOver()
{
	auto MayRespawnComp = UPlayerRespawnComponent::Get(Game::May);
	MayRespawnComp.bManualGameOverTrigger = true;
}

/* Flag GameOver-behaviour for audio */
UFUNCTION(Category = "Player Health")
void FlagGameOverAudio(bool bIsAudioGameOver)
{
	for(auto Player : Game::GetPlayers())
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.FlagGameOverAudio(bIsAudioGameOver);
	}
}

/* Whether the players are game over right now. */
UFUNCTION(BlueprintPure, Category = "Player Health")
bool ArePlayersGameOver()
{
	auto MayRespawnComp = UPlayerRespawnComponent::Get(Game::May);
	return MayRespawnComp.bIsGameOver;
}

/* Bind what function should be called when a game over state is triggered. */
UFUNCTION(Category = "Player Health")
void BindPlayersGameOverEvent(FOnPlayersGameOver OnGameOver)
{
	auto MayRespawnComp = UPlayerRespawnComponent::Get(Game::May);
	devEnsure(!MayRespawnComp.OnGameOver.IsBound(), "Binding game over event while another game over event is already bound.");
	MayRespawnComp.OnGameOver = OnGameOver;
}

/* Clear the current game-over state trigger event. */
UFUNCTION(Category = "Player Health")
void ClearPlayersGameOverEvent()
{
	auto MayRespawnComp = UPlayerRespawnComponent::Get(Game::May);
	MayRespawnComp.OnGameOver.Clear();
}

/**
 * Ensure that any players that are dead are immediately made alive again.
 * This does not actually respawn them or teleport them, just makes them alive.
 */
UFUNCTION(Category = "Player Health")
void ForcePlayersToBeAlive()
{
	for (auto Player : Game::Players)
	{
		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		auto HealthComp = UPlayerHealthComponent::Get(Player);

		if (HealthComp.bIsDead)
			HealthComp.bForceAlive = true;
	}
}

/* Mark the player as invulnerable with the instigator. Invulnerable players can't take damage but can still be killed. */
UFUNCTION(Category = "Player Health")
void AddPlayerInvulnerability(AHazePlayerCharacter Player, UObject Instigator)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	HealthComp.AddInvulnerability(Instigator);
}

/* Remove the invulnerability added with the specified instigator. */
UFUNCTION(Category = "Player Health")
void RemovePlayerInvulnerability(AHazePlayerCharacter Player, UObject Instigator)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	HealthComp.RemoveInvulnerability(Instigator);
}

/* Temporarily mark the player as invulnerable until the duration is complete. */
UFUNCTION(Category = "Player Health")
void AddPlayerInvulnerabilityDuration(AHazePlayerCharacter Player, float Duration)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
	HealthComp.AddInvulnerabilityDuration(Duration);
}

/* Get the god mode status for the player. */
UFUNCTION(Category = "Player Health")
EGodMode GetGodMode(AHazePlayerCharacter Player)
{
	UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
    return HealthComp.GodMode;
}

/* Bind a delegate to be called whenever the player dies. */
UFUNCTION(Category = "Player Health")
void BindOnPlayerDiedEvent(FOnPlayerDied OnPlayerDied)
{
	for (auto Player : Game::GetPlayers())
	{
		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
		HealthComp.OnPlayerDied = OnPlayerDied;
	}
}

/* Clear the previous bind for the player death event. */
UFUNCTION(Category = "Player Health")
void ClearOnPlayerDiedEvent()
{
    for (auto Player : Game::GetPlayers())
    {
        UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player); 
        HealthComp.OnPlayerDied.Clear();
    }
}

/* Bind a delegate to be called whenever the player respawns. */
UFUNCTION(Category = "Player Health")
void BindOnPlayerRespawnedEvent(FOnRespawnTriggered OnPlayerRespawned)
{
	for (auto Player : Game::GetPlayers())
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player); 
		RespawnComp.OnRespawn.AddUFunction(OnPlayerRespawned.UObject, OnPlayerRespawned.FunctionName);
	}
}

/* Unbind a previously bound event called when the player respawns */
UFUNCTION(Category = "Player Health")
void UnbindOnPlayerRespawnedEvent(UObject EventObject)
{
	for (auto Player : Game::GetPlayers())
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player); 
		RespawnComp.OnRespawn.UnbindObject(EventObject);
	}
}

/* Unbind a previously bound event called when the player respawns */
UFUNCTION(Category = "Player Health")
void UnbindOnPlayerRespawnedEventDelegate(FOnRespawnTriggered OnRespawnedEvent)
{
	for (auto Player : Game::GetPlayers())
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player); 
		RespawnComp.OnRespawn.Unbind(OnRespawnedEvent.UObject, OnRespawnedEvent.FunctionName);
	}
}