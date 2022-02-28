import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.PlayerHealth.PlayerHealthComponent;

event void FOnPlayerKilledByDeathVolume(AHazePlayerCharacter Player);

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class ADeathVolume : AVolume
{
    /* Whether this death volume is currently enabled. */
    UPROPERTY(BlueprintReadOnly, Category = "Death")
    bool bEnabled = true;

    /* Whether this death volume kills the cody player. */
    UPROPERTY(BlueprintReadOnly, Category = "Death", AdvancedDisplay)
    bool bKillsCody = true;

    /* Whether this death volume kills the cody player. */
    UPROPERTY(BlueprintReadOnly, Category = "Death", AdvancedDisplay)
    bool bKillsMay = true;

    /* The death effect that's played when dying here. */
    UPROPERTY(Category = "Death")
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

    /**
	 * Should the default death effect used when no DeathEffect is specified be the DefaultDeathVolumeEffect?
	 * If set to false, the DefaultDeathEffect will be used instead.
	 */
    UPROPERTY(Category = "Death", AdvancedDisplay)
	bool bDefaultToDeathVolumeEffect = true;

	/* Triggered whenever a player is killed by this death volume. */
	UPROPERTY()
	FOnPlayerKilledByDeathVolume OnPlayerKilledByDeathVolume;

    default Shape::SetVolumeBrushColor(this, FLinearColor::Red);

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (!bEnabled)
        {
            SetActorEnableCollision(false);
        }
    }

    UFUNCTION()
    void EnableDeathVolume()
    {
        if (!bEnabled)
        {
            bEnabled = true;
            SetActorEnableCollision(true);
        }
    }

    UFUNCTION()
    void DisableDeathVolume()
    {
        if (bEnabled)
        {
            SetActorEnableCollision(false);
            bEnabled = false;
        }
    }

    UFUNCTION()
    void EnablePlayerKillableByDeathVolume(AHazePlayerCharacter Player)
    {
        if (Player.Player == EHazePlayer::Cody)
            bKillsCody = true;
        if (Player.Player == EHazePlayer::May)
            bKillsMay = true;
    }

    UFUNCTION()
    void DisablePlayerKillableByDeathVolume(AHazePlayerCharacter Player)
    {
        if (Player.Player == EHazePlayer::Cody)
            bKillsCody = false;
        if (Player.Player == EHazePlayer::May)
            bKillsMay = false;
    }

    UFUNCTION()
    void EnableCodyKillableByDeathVolume()
    {
        bKillsCody = true;
    }

    UFUNCTION()
    void EnableMayKillableByDeathVolume()
    {
        bKillsMay = true;
    }

    UFUNCTION()
    void DisableCodyKillableByDeathVolume()
    {
        bKillsCody = false;
    }

    UFUNCTION()
    void DisableMayKillableByDeathVolume()
    {
        bKillsMay = false;
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (!bEnabled)
            return;

        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

        if (Player.Player == EHazePlayer::Cody && !bKillsCody)
            return;
        if (Player.Player == EHazePlayer::May && !bKillsMay)
            return;

		if (Player.HasControl() && Player.CanPlayerBeKilled())
			LeaveCrumbForPlayerKilledByVolume(Player);

		if (!DeathEffect.IsValid() && bDefaultToDeathVolumeEffect)
		{
			// Use the default DeathVolume effect if we don't have one set
			auto HealthComp = UPlayerHealthComponent::Get(Player);
			KillPlayer(Player, HealthComp.GetDefaultEffect_DeathVolume());
		}
		else
		{
			KillPlayer(Player, DeathEffect);
		}
    }

	void LeaveCrumbForPlayerKilledByVolume(AHazePlayerCharacter Player)
	{
		UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
		CrumbParams.AddObject(n"Player", Player);
		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_PlayerKilledByVolume"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_PlayerKilledByVolume(FHazeDelegateCrumbData CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		OnPlayerKilledByDeathVolume.Broadcast(Player);
	}
};