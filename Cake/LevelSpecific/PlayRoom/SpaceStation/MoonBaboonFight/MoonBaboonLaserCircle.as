import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class AMoonBaboonLaserCircle : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent LaserEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactSystem;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bActive)
		{
			float HorizontalDistanceToPlayer = GetHorizontalDistanceTo(Game::GetMay());
			float VerticalDistanceToPlayer = GetVerticalDistanceTo(Game::GetMay());

			if (HorizontalDistanceToPlayer < 800.f && VerticalDistanceToPlayer < 50.f && Game::GetMay().HasControl())
			{
				Game::May.DamagePlayerHealth(0.25f, DamageEffect, DeathEffect);
			}
		}
	}

	UFUNCTION()
	void ActivateLaserCircle(bool bSpawnImpactEffect = true)
	{
		SetActorTickEnabled(true);
		LaserEffect.Activate(true);
		bActive = true;
		
		if (bSpawnImpactEffect)
			Niagara::SpawnSystemAtLocation(ImpactSystem, ActorLocation);

		System::SetTimer(this, n"DestroyLaserCircle", 200.f, false);
	}

	void DeactivateLaserCircle()
	{
		SetActorTickEnabled(false);
		LaserEffect.Deactivate();
		bActive = false;
	}

	UFUNCTION()
	void DestroyLaserCircle()
	{
		DestroyActor();
	}
}