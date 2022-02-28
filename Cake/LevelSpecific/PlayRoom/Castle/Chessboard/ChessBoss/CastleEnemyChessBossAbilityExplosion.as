import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyChessBossAbilityExplosion : UChessBossAbility
{
	default CapabilityTags.Add(n"QueenAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;
	UNiagaraComponent NiagaraComp;

	UPROPERTY()
	float ExplosionTimer = 12.f;
	UPROPERTY()
	float PostExplosionBuffer = 3.f;
	float ActualExplosionTimer;

	bool bExploded = false;
	bool bExplosionInterrupted = false;

	UPROPERTY()
	const float DamageRequiredToInterruptExplosion = 250.f;
	float DamageTakenDuringExplosion = 0.f;

	default Cooldown = 15.f;

	default BossAbility.Priority = EBossAbilityPriority::High;
	default BossAbility.Phase = 3;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		if (ExplosionEffect != nullptr)
		{
			NiagaraComp = Niagara::SpawnSystemAttached(ExplosionEffect, Owner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
			NiagaraComp.Deactivate();
			NiagaraComp.SetAutoActivate(false);
		}

		OwningBoss.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	}

	UFUNCTION()
	bool ShouldActivateAbility() const
	{
		if (CurrentCooldown <= 0.f)
			return true;

		return false;
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		if (bExplosionInterrupted && ActiveDuration >= PostExplosionBuffer)
			return true;

		if (ActiveDuration >= ExplosionTimer + PostExplosionBuffer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		DamageTakenDuringExplosion = 0.f;
		bExploded = false;
		bExplosionInterrupted = false;

		Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"ChessboardMovement", this);
		Owner.BlockCapabilities(n"CastleEnemyKnockback", this);

		ActualExplosionTimer = FMath::Max(ExplosionTimer - 1.5f, 3.f);
		NiagaraComp.SetFloatParameter(n"User.Life", ActualExplosionTimer);
		NiagaraComp.Activate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"ChessboardMovement", this);
		Owner.UnblockCapabilities(n"CastleEnemyKnockback", this);

		NiagaraComp.Deactivate();	

		AbilitiesComp.AbilityFinished();

		CurrentCooldown = Cooldown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		//PrintScaled("Duration = " + ActiveDuration + " || Damage Taken = " + DamageTakenDuringExplosion + "/" + DamageRequiredToInterruptExplosion, Scale = 2.f);

		if (ActiveDuration >= ExplosionTimer && !bExploded)
			Explode();

		if (DamageTakenDuringExplosion >= DamageRequiredToInterruptExplosion && !bExploded && !bExplosionInterrupted)
			Interrupt();
	}

	void Explode()
	{
		bExploded = true;

		for (auto ChessPiece : PieceComp.Chessboard.AllChessPieces)
		{
			ChessPiece.SetEnemyHealth(ChessPiece.Health + 600.f);
		}

		// for (AHazePlayerCharacter Player : Game::GetPlayers())
		// {
		// 	FCastlePlayerDamageEvent Evt;
		// 	Evt.DamageSource = Enemy;
		// 	Evt.DamageDealt = 90.f;
		// 	Evt.DamageLocation = Player.ActorCenterLocation;
		// 	Evt.DamageDirection = Math::ConstrainVectorToPlane(Player.ActorLocation - Owner.ActorLocation, FVector::UpVector);
		// 	//Evt.DamageEffect = DamageEffect;

		// 	Player.DamageCastlePlayer(Evt);
		// }
	}

	void Interrupt()
	{
		bExplosionInterrupted = true;

		NiagaraComp.Deactivate();	
	}

	UFUNCTION()
	void OnTakeDamage(ACastleEnemy Enemy, FCastleEnemyDamageEvent Event)
	{
		DamageTakenDuringExplosion += Event.DamageDealt;
	}
}