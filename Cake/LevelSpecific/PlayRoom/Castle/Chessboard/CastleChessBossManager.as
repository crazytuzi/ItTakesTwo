import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessBossWidget;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessAudio.CastleChessBossAudioManager;

event void FOnPhaseChanged(int PhaseNumber);

class ACastleChessBossManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = Billboard)
	UTextRenderComponent Text;
	default Text.bHiddenInGame = true;

	default SetActorTickEnabled(false);

	UPROPERTY()
	ACastleEnemy King;
	UPROPERTY()
	ACastleEnemy Queen;
	UPROPERTY()
	TSubclassOf<UBossHealthBarWidget> BossWidgetType;
	UBossHealthBarWidget BossWidget;

	UPROPERTY()
	ACastleChessBossAudioManager BossAudioManager;

	UFUNCTION()
	void ShowBossWidget()
	{		
		King.OnTakeDamage.AddUFunction(this, n"OnKingTakeDamage");
		Queen.OnTakeDamage.AddUFunction(this, n"OnQueenTakeDamage");

		FText BossName = NSLOCTEXT("KingAndQueen", "Name", "King and Queen");
		BossWidget = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(BossWidgetType));
		BossWidget.InitBossHealthBar(BossName, King.MaxHealth + Queen.MaxHealth);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Queen.SetCapabilityAttributeObject(n"BossManager", this);

		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void OnKingTakeDamage(ACastleEnemy Enemy, FCastleEnemyDamageEvent Event)
	{	
		if (Event.DamageType != ECastleEnemyDamageType::Mirror)
			DamageBoss(Queen, King, Event.DamageDealt);

		UpdateHealthPercentage();
	}

	UFUNCTION()
	void OnQueenTakeDamage(ACastleEnemy Enemy, FCastleEnemyDamageEvent Event)
	{
		if (Event.DamageType != ECastleEnemyDamageType::Mirror)
			DamageBoss(King, Queen, Event.DamageDealt);
			
		UpdateHealthPercentage();
	}

	void UpdateHealthPercentage()
	{
		float CurrentHealth = float(Queen.Health) + float(King.Health);
		BossWidget.SetHealthAsDamage(CurrentHealth);
	}

	void DamageBoss(ACastleEnemy Enemy, ACastleEnemy DamageDealer, float Damage)
	{
		FCastleEnemyDamageEvent DamageEvent;

		DamageEvent.DamageDealt = Damage;
		DamageEvent.DamageSource = DamageDealer;
		DamageEvent.DamageType = ECastleEnemyDamageType::Mirror;

		Enemy.TakeDamage(DamageEvent);
	}

	void KillBosses()
	{
		King.SetCapabilityActionState(n"BossDead", EHazeActionState::Active);
		Queen.SetCapabilityActionState(n"BossDead", EHazeActionState::Active);
	}
}