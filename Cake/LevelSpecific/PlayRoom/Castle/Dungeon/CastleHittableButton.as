import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleHittableComponent;

event void FOnCastleHittableButtonTriggered();

class ACastleHittableButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCastleHittableComponent HittableComp;

	UPROPERTY(Category = "Hittable Button")
	float Cooldown = 4.f;

	UPROPERTY()
	FOnCastleHittableButtonTriggered OnTriggered;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	private float CooldownTimer = 0.f;
	private bool bAlreadyTriggered = false;
	private bool bOnCooldownControl = false;
	private bool bOnCooldownRemote = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HittableComp.OnHitByCastlePlayer.AddUFunction(this, n"HitByCastlePlayer");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CooldownTimer > 0.f)
		{
			CooldownTimer -= DeltaTime;
			if (CooldownTimer <= 0.f)
			{
				CooldownTimer = 0.f;
				NetCooldownComplete(HasControl());
				SetActorTickEnabled(false);
			}
		}
	}

	UFUNCTION()
	private void HitByCastlePlayer(AHazePlayerCharacter Player, FVector HitLocation)
	{
		if (bAlreadyTriggered)
			return;

		if (Player.HasControl())
			NetTrigger(HasControl());
	}

	UFUNCTION(NetFunction)
	private void NetTrigger(bool bFromControl)
	{
		// Ignore if both players triggered it at the same time
		if (bAlreadyTriggered)
			return;

		bOnCooldownControl = true;
		if (Network::IsNetworked())
			bOnCooldownRemote = true;
		bAlreadyTriggered = true;

		PlayHitAnimation();

		OnTriggered.Broadcast();
		CooldownTimer = Cooldown;
		SetActorTickEnabled(true);
	}

	UFUNCTION(NetFunction)
	private void NetCooldownComplete(bool bFromControl)
	{
		if (bFromControl)
			bOnCooldownControl = false;
		else
			bOnCooldownRemote = false;

		if (!bOnCooldownRemote && !bOnCooldownControl)
			bAlreadyTriggered = false;
	}

	UFUNCTION(BlueprintEvent)
	void PlayHitAnimation()
	{
	}
}