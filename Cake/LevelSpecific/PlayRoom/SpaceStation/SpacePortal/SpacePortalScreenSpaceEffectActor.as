import Peanuts.Fades.FadeStatics;

class ASpacePortalScreenSpaceEffectActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent EnterEffectComp;
	default EnterEffectComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ExitEffectComp;
	default ExitEffectComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	AHazePlayerCharacter TargetPlayer;
	bool bEnabled = false;

	void Activate(bool bEnterEffect)
	{
		if (!bEnabled)
		{
			EnableActor(nullptr);
			bEnabled = true;
		}

		/*if (bEnterEffect)
			EnterEffectComp.Activate(true);
		else
			ExitEffectComp.Activate(true);*/

		if (TargetPlayer != nullptr)
		{
			TargetPlayer.FadePlayerToColor(FLinearColor::White, 1.f, 0.25f, 0.25f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetPlayer == nullptr)
			return;

		FVector Loc = TargetPlayer.ViewLocation + (TargetPlayer.ViewRotation.ForwardVector * 20.f);
		TeleportActor(Loc, FRotator::ZeroRotator);

		if (!EnterEffectComp.IsActive() && !ExitEffectComp.IsActive())
		{
			bEnabled = false;
			DisableActor(nullptr);
		}
	}
}