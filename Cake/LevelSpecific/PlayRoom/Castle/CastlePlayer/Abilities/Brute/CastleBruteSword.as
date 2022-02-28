UCLASS(Abstract)
class ACastleBruteSword : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent SwordMesh;
	default SwordMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SwordSwingEffect;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent SwordFlameEffect;

	void HideSword()
	{
		SwordMesh.SetVisibility(false, true);
		Game::GetMay().SetCapabilityActionState(n"AudioHideSword", EHazeActionState::ActiveForOneFrame);
	}

	void ShowSword()
	{
		SwordMesh.SetVisibility(true, true);
		Game::GetMay().SetCapabilityActionState(n"AudioShowSword", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void FlameOn()
	{
		SwordFlameEffect.Activate();
		SwordMesh.SetScalarParameterValueOnMaterialIndex(1, n"Strength", 1.f);
	}

	UFUNCTION()
	void FlameOff()
	{
		SwordFlameEffect.Deactivate();
		SwordMesh.SetScalarParameterValueOnMaterialIndex(1, n"Strength", 0.f);
	}
}