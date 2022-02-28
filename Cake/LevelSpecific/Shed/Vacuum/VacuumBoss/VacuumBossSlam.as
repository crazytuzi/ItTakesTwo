import Vino.Checkpoints.Statics.DeathStatics;
import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Cake.LevelSpecific.Shed.Vacuum.VacuumBoss.VacuumBossBomb;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.PlayerHealth.PlayerHealthComponent;

event void FOnVacuumBossSlamDeactivated(AVacuumBossSlam SlamActor);

UCLASS(Abstract)
class AVacuumBossSlam : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ShockwaveEffect;
	default ShockwaveEffect.bAutoActivate = false;

	float CurrentRadius = 0.f;
    float MaximumRadius = 5000.f;
	float ExpansionSpeed = 1200.f;

	float DamageWidth = 200.f;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> PlayerDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect SlamRumble;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> SlamCamShake;

	bool bActive = false;

	FOnVacuumBossSlamDeactivated OnSlamDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	void ActivateSlam(FVector SlamLocation)
	{
		SetActorTickEnabled(true);
		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			CurPlayer.PlayForceFeedback(SlamRumble, false, true, n"Slam", 2.f);
			CurPlayer.PlayCameraShake(SlamCamShake, 0.25f);
		}

		CurrentRadius = 0.f;
		SetActorLocation(SlamLocation);

		ShockwaveEffect.Activate(true);
		bActive = true;
	}

	void DeactivateSlam()
	{
		SetActorTickEnabled(false);
		bActive = false;
		OnSlamDeactivated.Broadcast(this);
		ShockwaveEffect.Deactivate();
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if (!bActive)
			return;

		CurrentRadius += ExpansionSpeed * DeltaTime;
		// System::DrawDebugCylinder(ActorLocation, ActorLocation + FVector(0.f, 0.f, 50.f), CurrentRadius - DamageWidth, 32, FLinearColor::Red, 0.f, 10.f);
		// System::DrawDebugCylinder(ActorLocation, ActorLocation + FVector(0.f, 0.f, 50.f), CurrentRadius + DamageWidth, 32, FLinearColor::Red, 0.f, 10.f);
		// Print("" + CurrentRadius);

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			bool bDamagePlayer = false;
			FVector PlayerLocation = CurPlayer.ActorLocation;
			float HorizontalDistance = GetHorizontalDistanceTo(CurPlayer);
			float VerticalDistance = GetVerticalDistanceTo(CurPlayer);
			if (HorizontalDistance > CurrentRadius - DamageWidth && HorizontalDistance < CurrentRadius + DamageWidth)
				bDamagePlayer = true;
			if (VerticalDistance >= 50.f)
				bDamagePlayer = false;

			if (bDamagePlayer && CurPlayer.HasControl())
			{
				// KnockdownActor(CurPlayer, FVector::ZeroVector, 0.5f);
				// PlayerTakeDamage(CurPlayer, DamageEffect, 0.25f);
				DamagePlayerHealth(CurPlayer, 0.5f, PlayerDamageEffect);
			}
		}

		TArray<AVacuumBossBomb> Bombs;
		GetAllActorsOfClass(Bombs);

		for (AVacuumBossBomb CurBomb : Bombs)
		{
			float Distance = GetHorizontalDistanceTo(CurBomb);
			if (Distance > CurrentRadius - DamageWidth && Distance < CurrentRadius + DamageWidth && !CurBomb.bGoingThroughHose && !CurBomb.bShot && CurBomb.bLanded)
				CurBomb.NetDestroyBomb();
		}

		if (CurrentRadius >= MaximumRadius)
			DeactivateSlam();
    }

	// AVacuumHoseActor Hose = Cast<AVacuumHoseActor>(OtherActor);

	// if (Hose != nullptr)
	// {
	//     Hose.ThrowPlayersOffOfHose();
	// }
}